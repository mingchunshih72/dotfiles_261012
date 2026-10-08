return {
  -- 讓終端背景色跟 nvim 主題一致
  { "typicode/bg.nvim", lazy = false },

  -- 更好的 vim.ui.input / vim.ui.select（cscope 的輸入框會變漂亮）
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = { input = { border = "rounded" } },
  },
}
