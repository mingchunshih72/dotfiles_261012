return {
  formatters_by_ft = {
    c    = { "clang_format" },
    cpp  = { "clang_format" },
    lua  = { "stylua" },
    sh   = { "shfmt" },
    bash = { "shfmt" },
  },

  formatters = {
    clang_format = {
      -- 專案有 .clang-format 就用它；沒有就用 Linux kernel 風格
      prepend_args = function(_, ctx)
        local found = vim.fs.find(".clang-format", { upward = true, path = ctx.dirname })[1]
        if found then return {} end
        return { "--style={BasedOnStyle: LLVM, IndentWidth: 4, UseTab: Never, ColumnLimit: 100}" }
      end,
    },
    shfmt = { prepend_args = { "-i", "2", "-ci" } },
  },

  -- 不自動格式化：C 專案常有既有排版，手動 <leader>lf 比較安全
  -- 想開自動就把下面兩行註解拿掉
  -- format_on_save = { timeout_ms = 1000, lsp_fallback = true },
}
