require "nvchad.autocmds"

local au = vim.api.nvim_create_autocmd
local group = function(name)
  return vim.api.nvim_create_augroup("my_" .. name, { clear = true })
end

-- ─────────────────────────────────────────────────────────────
-- 行尾空白：顯示 + 存檔自動清除
-- 修正：原本在唯讀/特殊 buffer 會噴 E21，且會把游標跳掉
-- ─────────────────────────────────────────────────────────────
local ws = group "whitespace"

au({ "BufWinEnter", "InsertLeave" }, {
  group = ws,
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" then
      pcall(vim.cmd, [[match ExtraWhitespace /\s\+$/]])
    end
  end,
})

au("InsertEnter", {
  group = ws,
  pattern = "*",
  callback = function() pcall(vim.cmd, "match none") end,
})

-- 不想自動清空白的 filetype
local no_strip = { markdown = true, diff = true, gitcommit = true, snippets = true }

au("BufWritePre", {
  group = ws,
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable or vim.bo.readonly then return end
    if vim.bo.buftype ~= "" then return end
    if no_strip[vim.bo.filetype] then return end

    local view = vim.fn.winsaveview()
    pcall(function() vim.cmd [[silent! keeppatterns %s/\s\+$//e]] end)
    vim.fn.winrestview(view)
  end,
})

-- ─────────────────────────────────────────────────────────────
-- 複製時高亮一下
-- ─────────────────────────────────────────────────────────────
au("TextYankPost", {
  group = group "yank",
  callback = function() vim.hl.on_yank { higroup = "IncSearch", timeout = 150 } end,
})

-- ─────────────────────────────────────────────────────────────
-- 重開檔案時回到上次的位置
-- ─────────────────────────────────────────────────────────────
au("BufReadPost", {
  group = group "lastpos",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ─────────────────────────────────────────────────────────────
-- 依 filetype 的縮排規則
-- ─────────────────────────────────────────────────────────────
au("FileType", {
  group = group "ft_indent",
  pattern = { "make", "automake" },
  callback = function()
    -- Makefile 一定要真實 Tab，否則 make 會報 "missing separator"
    vim.bo.expandtab = false
    vim.bo.tabstop = 8
    vim.bo.shiftwidth = 8
    vim.bo.softtabstop = 0
  end,
})

au("FileType", {
  group = group "ft_indent_c",
  pattern = { "c", "cpp", "h" },
  callback = function()
    vim.bo.cindent = true
    vim.bo.commentstring = "/* %s */"
    -- C 的 keyword 允許 # 開頭，方便搜 #define
    vim.opt_local.iskeyword:append "#"
  end,
})

au("FileType", {
  group = group "ft_indent_sh",
  pattern = { "sh", "bash", "zsh", "yaml", "json", "lua" },
  callback = function()
    vim.bo.expandtab = true
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})

-- ─────────────────────────────────────────────────────────────
-- q 關閉輔助視窗
-- ─────────────────────────────────────────────────────────────
au("FileType", {
  group = group "quickclose",
  pattern = { "qf", "help", "man", "lspinfo", "checkhealth", "startuptime" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})

-- quickfix 視窗自動佔滿寬度並放底部
au("FileType", {
  group = group "qfwin",
  pattern = "qf",
  callback = function() vim.cmd "wincmd J | resize 12" end,
})
