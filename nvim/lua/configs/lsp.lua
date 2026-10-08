-- ════════════════════════════════════════════════════════════
--  LSP 設定（Neovim 0.11 的 vim.lsp.config / vim.lsp.enable API）
--  重點修正：原本從未呼叫 nvchad defaults()，導致 gd/gD 等
--            LSP 快捷鍵完全沒註冊，才會「function 無法跳轉」。
-- ════════════════════════════════════════════════════════════

local nvlsp = require "nvchad.configs.lspconfig"

-- 1) 套用 NvChad 的 on_attach / capabilities / 診斷樣式（會註冊 gd、gD…）
nvlsp.defaults()

-- 2) 全域預設
vim.lsp.config("*", {
  capabilities = nvlsp.capabilities,
  on_init = nvlsp.on_init,
})

-- ─────────────────────────────────────────────────────────────
--  clangd（C / C++ 主力）
-- ─────────────────────────────────────────────────────────────
vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",             -- 背景建索引 -> 跨檔跳轉/找參考
    "--clang-tidy",                   -- 靜態檢查
    "--completion-style=detailed",
    "--header-insertion=never",       -- 不要自動亂插 #include
    "--all-scopes-completion",
    "--cross-file-rename",
    "--pch-storage=memory",
    "--fallback-style=llvm",
    -- 讓 clangd 問編譯器拿內建 include 路徑（交叉編譯很重要）
    "--query-driver=/usr/bin/*gcc*,/usr/bin/*clang*,/usr/bin/*g++*,/opt/**/bin/*gcc*,/usr/local/**/bin/*gcc*",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = {
    ".clangd",
    "compile_commands.json",
    "build/compile_commands.json",
    "compile_flags.txt",
    "configure.ac",
    "Makefile",
    "CMakeLists.txt",
    ".git",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
})

-- ─────────────────────────────────────────────────────────────
--  其他語言（有裝才會啟動，沒裝不會報錯）
-- ─────────────────────────────────────────────────────────────
vim.lsp.config("bashls", { filetypes = { "sh", "bash", "zsh" } })

local servers = { "clangd", "bashls", "lua_ls", "cmake", "pyright" }
for _, s in ipairs(servers) do
  -- 只在該 server 的執行檔存在時才 enable
  local bin = ({
    clangd = "clangd",
    bashls = "bash-language-server",
    lua_ls = "lua-language-server",
    cmake = "cmake-language-server",
    pyright = "pyright-langserver",
  })[s]
  if bin and vim.fn.executable(bin) == 1 then
    pcall(vim.lsp.enable, s)
  end
end

-- ════════════════════════════════════════════════════════════
--  compile_commands.json 產生工具
--  clangd 沒有它就只能猜 include 路徑 -> 跳轉會半殘
-- ════════════════════════════════════════════════════════════
local function project_root()
  local markers = { "compile_commands.json", "Makefile", "CMakeLists.txt", ".git" }
  local found = vim.fs.find(markers, { upward = true, path = vim.fn.expand "%:p:h" })[1]
  return found and vim.fs.dirname(found) or vim.fn.getcwd()
end

-- :CcJson [make target]   用 bear 攔截 make 產生 compile_commands.json
vim.api.nvim_create_user_command("CcJson", function(o)
  if vim.fn.executable "bear" == 0 then
    vim.notify("找不到 bear，請先執行： sudo apt install bear", vim.log.levels.ERROR)
    return
  end
  local root = project_root()
  local target = o.args ~= "" and o.args or ""
  local cmd = string.format("cd %s && make clean >/dev/null 2>&1; bear -- make %s", vim.fn.shellescape(root), target)
  vim.notify("產生 compile_commands.json ...\n" .. root, vim.log.levels.INFO)
  vim.fn.jobstart({ "sh", "-c", cmd }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("compile_commands.json 完成，重啟 LSP…", vim.log.levels.INFO)
          vim.cmd "LspRestart"
        else
          vim.notify("bear -- make 失敗（exit " .. code .. "），請在終端手動跑看錯誤", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end, { nargs = "?", desc = "用 bear 產生 compile_commands.json" })

-- :CcFlags   退而求其次：寫一份 compile_flags.txt（給沒有 bear / 單純資料夾用）
vim.api.nvim_create_user_command("CcFlags", function()
  local root = project_root()
  local path = root .. "/compile_flags.txt"
  local incs = { "-std=gnu11", "-Wall", "-I." }
  for _, d in ipairs { "include", "inc", "src", "lib", "common" } do
    if vim.fn.isdirectory(root .. "/" .. d) == 1 then
      table.insert(incs, "-I" .. d)
    end
  end
  vim.fn.writefile(incs, path)
  vim.notify("已寫入 " .. path .. "\n" .. table.concat(incs, " "), vim.log.levels.INFO)
  vim.cmd "LspRestart"
end, { desc = "產生 compile_flags.txt（clangd 後備方案）" })

-- ════════════════════════════════════════════════════════════
--  :CSwitch  —  .c ⇄ .h 切換
--  （nvim-lspconfig 在 Neovim 0.11 的新 API 下不再提供
--    :ClangdSwitchSourceHeader，所以自己實作）
--  1. 先問 clangd 的 textDocument/switchSourceHeader
--  2. clangd 沒回答就用檔名規則在專案裡找
-- ════════════════════════════════════════════════════════════
local SRC_EXT = { "c", "cc", "cpp", "cxx", "m", "mm" }
local HDR_EXT = { "h", "hh", "hpp", "hxx" }

local function switch_by_filename()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then return false end
  local stem = vim.fn.fnamemodify(path, ":r")
  local base = vim.fn.fnamemodify(path, ":t:r")
  local ext = vim.fn.fnamemodify(path, ":e")

  local want = vim.tbl_contains(HDR_EXT, ext) and SRC_EXT or HDR_EXT

  -- 1) 同目錄同名
  for _, e in ipairs(want) do
    local cand = stem .. "." .. e
    if vim.fn.filereadable(cand) == 1 then
      vim.cmd.edit(vim.fn.fnameescape(cand))
      return true
    end
  end

  -- 2) 專案內搜同名（include/ 與 src/ 分開放的常見結構）
  local root = vim.fs.root(0, { "compile_commands.json", "Makefile", "CMakeLists.txt", ".git" })
    or vim.fn.getcwd()
  for _, e in ipairs(want) do
    local hits = vim.fs.find(base .. "." .. e, { path = root, type = "file", limit = 5 })
    if #hits > 0 then
      vim.cmd.edit(vim.fn.fnameescape(hits[1]))
      return true
    end
  end
  return false
end

vim.api.nvim_create_user_command("CSwitch", function()
  local clients = vim.lsp.get_clients { bufnr = 0, name = "clangd" }
  if #clients > 0 then
    local client = clients[1]
    client:request("textDocument/switchSourceHeader", {
      uri = vim.uri_from_bufnr(0),
    }, function(err, result)
      if not err and result and result ~= "" then
        vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(result)))
      elseif not switch_by_filename() then
        vim.notify("找不到對應的 .c / .h", vim.log.levels.WARN)
      end
    end, 0)
    return
  end
  if not switch_by_filename() then
    vim.notify("找不到對應的 .c / .h", vim.log.levels.WARN)
  end
end, { desc = ".c <-> .h 切換" })

-- 保留舊名稱當別名，免得習慣改不過來
vim.api.nvim_create_user_command("ClangdSwitchSourceHeader", "CSwitch", { desc = ".c <-> .h 切換" })
