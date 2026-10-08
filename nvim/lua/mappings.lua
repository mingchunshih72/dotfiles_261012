require "nvchad.mappings"

local map = vim.keymap.set
local del = function(mode, lhs) pcall(vim.keymap.del, mode, lhs) end

local function m(mode, lhs, rhs, desc, extra)
  local o = vim.tbl_extend("force", { noremap = true, silent = true, desc = desc }, extra or {})
  map(mode, lhs, rhs, o)
end

-- ════════════════════════════════════════════════════════════
--  0. 解除衝突：<C-n> 留給 vim-visual-multi（檔案樹改用 F9/F10）
-- ════════════════════════════════════════════════════════════
del("n", "<C-n>")
del("v", "<C-n>")
del("i", "<C-n>")

-- ════════════════════════════════════════════════════════════
--  1. 基本
-- ════════════════════════════════════════════════════════════
m("n", ";", ":", "進入命令模式", { silent = false })
m("i", "jk", "<ESC>", "離開 insert mode")
m("n", "<Esc>", "<cmd>nohlsearch<cr>", "清除搜尋高亮")

-- 存檔 / 離開
m({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", "存檔")
m("n", "<leader>Q", "<cmd>qa<cr>", "全部離開")

-- 搬移游標時畫面保持居中
m("n", "<C-d>", "<C-d>zz", "下半頁")
m("n", "<C-u>", "<C-u>zz", "上半頁")
m("n", "n", "nzzzv", "下一個搜尋結果（居中）")
m("n", "N", "Nzzzv", "上一個搜尋結果（居中）")

-- 貼上不覆蓋暫存器 / 刪除不進暫存器
m("x", "<leader>p", [["_dP]], "貼上但不覆蓋剪貼簿")
m({ "n", "v" }, "<leader>y", [["+y]], "複製到系統剪貼簿")
m("n", "<leader>Y", [["+Y]], "複製整行到系統剪貼簿")

-- <C-a> 被 visual-multi 的 Select All 佔用，數字 +/- 改到這裡
m("n", "<leader>+", "<C-a>", "數字 +1")
m("n", "<leader>-", "<C-x>", "數字 -1")
m("v", "g<C-a>", "g<C-a>", "遞增數列")

-- ════════════════════════════════════════════════════════════
--  2. 大批選取
-- ════════════════════════════════════════════════════════════
m("n", "<leader>a", "ggVG", "全選整個檔案")
m("n", "gV", "`[v`]", "選取剛剛貼上/修改的區塊")
-- gv  = 重新選取上一次的 visual 區塊（內建）
-- <C-v> = 區塊選取（column 模式，內建）
-- <CR> / <BS> = treesitter 語法層逐層擴大/縮小（見 treesitter.lua）

-- ════════════════════════════════════════════════════════════
--  3. 大批位移 / 縮排
-- ════════════════════════════════════════════════════════════
-- 整行（或整塊）上下搬移，縮排自動跟著調整
m("n", "<A-j>", "<cmd>m .+1<cr>==", "本行往下移")
m("n", "<A-k>", "<cmd>m .-2<cr>==", "本行往上移")
m("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", "本行往下移")
m("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", "本行往上移")
m("v", "<A-j>", ":m '>+1<cr>gv=gv", "選取區往下移")
m("v", "<A-k>", ":m '<-2<cr>gv=gv", "選取區往上移")
-- 沒有 Alt 鍵的終端（或 WSL 吃掉 Alt）的備用鍵
m("v", "J", ":m '>+1<cr>gv=gv", "選取區往下移")
m("v", "K", ":m '<-2<cr>gv=gv", "選取區往上移")

-- visual 模式縮排後保持選取，可以連按
m("v", "<", "<gv", "減少縮排（保持選取）")
m("v", ">", ">gv", "增加縮排（保持選取）")
m("v", "<Tab>", ">gv", "增加縮排")
m("v", "<S-Tab>", "<gv", "減少縮排")

-- ════════════════════════════════════════════════════════════
--  4. 大批註解（Neovim 內建 commenting，支援 count 與 motion）
-- ════════════════════════════════════════════════════════════
map("n", "<leader>/", "gcc", { desc = "註解本行", remap = true })
map("v", "<leader>/", "gc",  { desc = "註解選取區", remap = true })
map("n", "<C-_>", "gcc", { desc = "註解本行 (Ctrl+/)", remap = true })
map("v", "<C-_>", "gc",  { desc = "註解選取區 (Ctrl+/)", remap = true })
map("n", "<C-/>", "gcc", { desc = "註解本行 (Ctrl+/)", remap = true })
map("v", "<C-/>", "gc",  { desc = "註解選取區 (Ctrl+/)", remap = true })
-- gcc=本行  gc{motion}=動作範圍  5gcc=往下 5 行  gcap=整段

-- ════════════════════════════════════════════════════════════
--  5. 搜尋 / 取代
-- ════════════════════════════════════════════════════════════
-- ── 區域（當前檔案） ──
m("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "本檔模糊搜尋")
m("n", "*", "*zzzv", "搜尋游標下的字（往下）")
m("n", "#", "#zzzv", "搜尋游標下的字（往上）")

-- ── 全域（整個專案，需要 ripgrep） ──
m("n", "<leader>fw", "<cmd>Telescope live_grep<cr>", "全域即時搜尋")
m("n", "<leader>fW", "<cmd>Telescope grep_string<cr>", "全域搜尋游標下的字")
m("v", "<leader>fW", function()
  vim.cmd 'noau normal! "vy'
  local sel = vim.fn.getreg "v"
  require("telescope.builtin").grep_string { search = sel }
end, "全域搜尋選取文字")

-- :grep 直接進 quickfix（大量結果時比 telescope 好用）
m("n", "<leader>fG", function()
  local w = vim.fn.input "grep (全專案) > "
  if w ~= "" then vim.cmd("silent grep! " .. vim.fn.shellescape(w) .. " | copen") end
end, "grep 到 quickfix")

-- 全域取代（先用 fw 找，<C-q> 丟進 quickfix，再 cdo 取代）
m("n", "<leader>rr", function()
  local old = vim.fn.input "取代前 > "
  if old == "" then return end
  local new = vim.fn.input "取代後 > "
  vim.cmd(("cdo s/%s/%s/gec | update"):format(old, new))
end, "對 quickfix 清單批次取代")

-- 本檔取代游標下的字
m("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], "本檔取代游標下的字", { silent = false })
m("v", "<leader>rw", [[:s///gI<Left><Left><Left><Left>]], "選取區取代", { silent = false })

-- ── 找檔案 ──
m("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "找檔案")
m("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<cr>", "找所有檔案（含隱藏）")
m("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "找已開 buffer")
m("n", "<leader>fo", "<cmd>Telescope oldfiles<cr>", "最近開過的檔案")
m("n", "<leader>fr", "<cmd>Telescope resume<cr>", "回到上次的搜尋結果")
m("n", "<leader>fq", "<cmd>Telescope quickfix<cr>", "瀏覽 quickfix")
m("n", "<leader>ft", "<cmd>TodoTelescope<cr>", "找 TODO/FIXME")
m("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", "搜尋所有快捷鍵")
m("n", "<leader>fM", "<cmd>Telescope marks<cr>", "找 mark（原 <leader>ma 已給 make）")
m("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "搜尋說明文件")

-- ════════════════════════════════════════════════════════════
--  6. LSP：函式/符號跳轉（clangd）
-- ════════════════════════════════════════════════════════════
-- gd / gD / <leader>ra 由 NvChad 的 on_attach 註冊，這裡補上其餘常用的
m("n", "gd", vim.lsp.buf.definition, "跳到定義")
m("n", "gD", vim.lsp.buf.declaration, "跳到宣告")
m("n", "gi", vim.lsp.buf.implementation, "跳到實作")
m("n", "gy", vim.lsp.buf.type_definition, "跳到型別定義")
m("n", "gr", "<cmd>Telescope lsp_references<cr>", "列出所有參考")
m("n", "K", vim.lsp.buf.hover, "顯示說明（簽章/型別）")
m("n", "gs", vim.lsp.buf.signature_help, "函式參數提示")
m("i", "<C-k>", vim.lsp.buf.signature_help, "函式參數提示")

m("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", "本檔 function/變數列表")
m("n", "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "全專案 symbol 列表")
m("n", "<leader>li", "<cmd>Telescope lsp_incoming_calls<cr>", "誰呼叫了這個函式")
m("n", "<leader>lo", "<cmd>Telescope lsp_outgoing_calls<cr>", "這個函式呼叫了誰")
m("n", "<leader>lr", vim.lsp.buf.rename, "重新命名（全專案）")
m({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code Action（快速修正）")
m("n", "<leader>lf", function() require("conform").format { lsp_fallback = true } end, "格式化檔案")
m("v", "<leader>lf", function() require("conform").format { lsp_fallback = true } end, "格式化選取區")
m("n", "<leader>lh", "<cmd>CSwitch<cr>", ".c <-> .h 切換")
m("n", "<leader>lI", "<cmd>LspInfo<cr>", "LSP 狀態")
m("n", "<leader>lR", "<cmd>LspRestart<cr>", "重啟 LSP")

-- ── 診斷（錯誤/警告） ──
m("n", "<leader>d", function()
  vim.diagnostic.open_float { focus = false, scope = "line", border = "rounded",
    source = "if_many", severity_sort = true }
end, "顯示本行診斷")
m("n", "]d", function() vim.diagnostic.jump { count = 1, float = false } end, "下一個診斷")
m("n", "[d", function() vim.diagnostic.jump { count = -1, float = false } end, "上一個診斷")
m("n", "]e", function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR } end, "下一個錯誤")
m("n", "[e", function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end, "上一個錯誤")
m("n", "<leader>dl", "<cmd>Trouble diagnostics toggle<cr>", "全專案診斷清單")
m("n", "<leader>db", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "本檔診斷清單")
m("n", "<leader>dt", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, "開/關診斷顯示")

-- ════════════════════════════════════════════════════════════
--  7. quickfix / location list（編譯錯誤、搜尋結果）
-- ════════════════════════════════════════════════════════════
m("n", "]q", "<cmd>cnext<cr>zz", "下一個 quickfix 項目")
m("n", "[q", "<cmd>cprev<cr>zz", "上一個 quickfix 項目")
m("n", "]Q", "<cmd>clast<cr>zz", "最後一個 quickfix")
m("n", "[Q", "<cmd>cfirst<cr>zz", "第一個 quickfix")
m("n", "<leader>qo", "<cmd>copen<cr>", "開 quickfix")
m("n", "<leader>qc", "<cmd>cclose<cr>", "關 quickfix")
m("n", "<leader>ql", "<cmd>Trouble qflist toggle<cr>", "quickfix（Trouble UI）")

-- ════════════════════════════════════════════════════════════
--  8. 編譯（make）
-- ════════════════════════════════════════════════════════════
m("n", "<leader>mm", function() vim.cmd "wa | make" end, "make（結果進 quickfix）")
m("n", "<leader>mc", function() vim.cmd "wa | make clean" end, "make clean")
m("n", "<leader>ma", function()
  local t = vim.fn.input "make target > "
  vim.cmd("wa | make " .. t)
end, "make <target>")
m("n", "<leader>mb", "<cmd>CcJson<cr>", "bear 產生 compile_commands.json")
m("n", "<leader>mf", "<cmd>CcFlags<cr>", "產生 compile_flags.txt")
m("n", "<leader>mt", "<cmd>TagsBuild<cr>", "重建 cscope.out + tags")

-- ════════════════════════════════════════════════════════════
--  9. 視窗 / 分割 / buffer
-- ════════════════════════════════════════════════════════════
m("n", "<leader>sv", "<cmd>vsplit<cr>", "垂直分割")
m("n", "<leader>sh", "<cmd>split<cr>", "水平分割")
m("n", "<leader>sq", "<cmd>close<cr>", "關閉此分割")
m("n", "<leader>so", "<cmd>only<cr>", "只留此分割")
m("n", "<C-Left>",  "<cmd>vertical resize -4<cr>", "視窗變窄")
m("n", "<C-Right>", "<cmd>vertical resize +4<cr>", "視窗變寬")
m("n", "<C-Down>",  "<cmd>resize -2<cr>", "視窗變矮")
m("n", "<C-Up>",    "<cmd>resize +2<cr>", "視窗變高")

-- 跳轉歷史
m("n", "<leader><leader>", "<C-^>", "切換上一個 buffer")

-- 檔案樹
m("n", "<F9>",  "<cmd>NvimTreeToggle<cr>", "開/關檔案樹")
m("n", "<F10>", "<cmd>NvimTreeFocus<cr>", "focus 檔案樹")

-- ════════════════════════════════════════════════════════════
--  10. which-key 群組說明
-- ════════════════════════════════════════════════════════════
pcall(function()
  require("which-key").add {
    { "<leader>f", group = "find / 搜尋" },
    { "<leader>l", group = "LSP / 程式碼" },
    { "<leader>d", group = "diagnostics / 診斷" },
    { "<leader>c", group = "cscope" },
    { "<leader>m", group = "make / 索引" },
    { "<leader>q", group = "quickfix" },
    { "<leader>r", group = "replace / 取代" },
    { "<leader>s", group = "split / swap" },
    { "<C-\\>",    group = "cscope (傳統鍵位)" },
    { "]", group = "下一個…" },
    { "[", group = "上一個…" },
  }
end)
