return {
  -- ── 多光標（批次改同名變數） ──────────────────────────────
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    init = function()
      vim.g.VM_default_mappings = 1
      vim.g.VM_maps = {
        ["Find Under"]         = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Select All"]         = "<C-a>",
        ["Skip Region"]        = "<C-x>",
        ["Remove Region"]      = "<C-p>",
        ["Add Cursor Down"]    = "<C-Down>",
        ["Add Cursor Up"]      = "<C-Up>",
      }
      vim.g.VM_theme = "iceblue"
      vim.g.VM_silent_exit = 1
    end,
  },

  -- ── 批次包圍 / 改括號引號 ────────────────────────────────
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- ── 批次對齊（對齊 #define、結構體欄位、=） ──────────────
  {
    "junegunn/vim-easy-align",
    cmd = "EasyAlign",
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, desc = "EasyAlign 對齊" },
    },
  },

  -- ── TODO / FIXME / XXX 高亮與搜尋 ────────────────────────
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },
}
