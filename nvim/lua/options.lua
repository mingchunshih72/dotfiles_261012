require "nvchad.options"

local opt = vim.opt
local o = vim.o

-- ─────────────────────────────────────────────────────────────
-- 行號 / 游標
-- ─────────────────────────────────────────────────────────────
opt.number         = true
opt.relativenumber = false      -- 需要時 <leader>rn 切換
opt.cursorline     = true
opt.cursorlineopt  = "both"
opt.scrolloff      = 6          -- 游標上下至少保留 6 行
opt.sidescrolloff  = 8
opt.signcolumn     = "yes"      -- 固定寬度，避免診斷圖示讓畫面跳動

-- ─────────────────────────────────────────────────────────────
-- 搜尋（修正：原本 hlsearch=false 導致搜尋完全看不到高亮）
-- ─────────────────────────────────────────────────────────────
opt.hlsearch   = true           -- 高亮所有匹配；<Esc> 可清除
opt.incsearch  = true           -- 邊打邊跳
opt.ignorecase = true           -- 預設不分大小寫
opt.smartcase  = true           -- 但你打了大寫就變成分大小寫
opt.inccommand = "split"        -- :%s/// 即時預覽

-- ─────────────────────────────────────────────────────────────
-- 縮排（C 開發）
-- ─────────────────────────────────────────────────────────────
opt.autoindent  = true
opt.smartindent = true
opt.smarttab    = true
opt.expandtab   = true          -- Tab -> 空白
opt.shiftwidth  = 4
opt.tabstop     = 4
opt.softtabstop = 4
opt.shiftround  = true          -- >> << 對齊到 shiftwidth 倍數

-- ─────────────────────────────────────────────────────────────
-- 顯示
-- ─────────────────────────────────────────────────────────────
opt.wrap        = false
opt.colorcolumn = "80,120"      -- 行寬提示線
opt.list        = true
opt.listchars   = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.splitright  = true
opt.splitbelow  = true
opt.termguicolors = true

-- ─────────────────────────────────────────────────────────────
-- 檔案 / 效能
-- ─────────────────────────────────────────────────────────────
opt.undofile   = true           -- 關掉 nvim 後仍可 undo
opt.undolevels = 10000
opt.swapfile   = false
opt.updatetime = 250            -- CursorHold / gitsigns 反應更快
opt.timeoutlen = 400            -- which-key 彈出速度
opt.confirm    = true           -- 未存檔時詢問而非報錯

-- 補全
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight   = 12

-- 大檔案不要 fold 卡住
opt.foldenable = false
opt.foldmethod = "indent"
opt.foldlevel  = 99

-- 讓 gf / :find 能找到 C header
opt.path:append { ".", "include", "inc", "src", "/usr/include", "**" }
opt.suffixesadd:append { ".c", ".h", ".cc", ".cpp", ".hpp" }

-- ctags：往上層目錄找 tags
opt.tags = "./tags,tags,./.git/tags"

-- grep 預設走 ripgrep（:grep <pattern> 直接進 quickfix）
if vim.fn.executable "rg" == 1 then
  o.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git'"
  o.grepformat = "%f:%l:%c:%m"
end

-- ─────────────────────────────────────────────────────────────
-- 高亮微調
-- ─────────────────────────────────────────────────────────────
local function tweak_hl()
  vim.api.nvim_set_hl(0, "CursorLine",      { bg = "#2a2a3f" })
  vim.api.nvim_set_hl(0, "CursorLineNr",    { fg = "#ffff66", bold = true })
  vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#8b2f3f" })
  vim.api.nvim_set_hl(0, "ColorColumn",     { bg = "#23232e" })
end
tweak_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = tweak_hl })
