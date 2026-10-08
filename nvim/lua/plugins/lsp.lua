return {
  -- ── Mason：管理 LSP / formatter 的安裝 ────────────────────
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate", "MasonLog" },
    opts = {
      PATH = "prepend",
      ui = { border = "rounded" },
    },
  },

  -- ── LSP 本體 ─────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { { "mason-org/mason.nvim", opts = {} } },
    config = function()
      require "configs.lsp"
    end,
  },

  -- ── 診斷 / 參考 / quickfix 清單 UI ───────────────────────
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    opts = {
      focus = true,
      warn_no_results = false,
      open_no_results = true,
    },
  },
}
