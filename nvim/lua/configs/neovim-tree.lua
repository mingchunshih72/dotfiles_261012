return {
  "nvim-tree/nvim-tree.lua",
  lazy = false,
  opts = {
    sort = { sorter = "case_sensitive" },
    view = {
      side = "right",
      width = 34,
      preserve_window_proportions = true,
    },
    renderer = {
      group_empty = true,
      highlight_git = true,
      indent_markers = { enable = true },
    },
    filters = {
      dotfiles = false,
      git_ignored = false,
      custom = { "^%.git$", "^%.cache$", "%.o$", "%.a$", "%.so$", "%.d$", "cscope%.out$", "^tags$" },
    },
    git = { enable = true },
    actions = { open_file = { quit_on_open = false, resize_window = true } },
    update_focused_file = { enable = true, update_root = false },
    diagnostics = { enable = true, show_on_dirs = true },
  },
  keys = {
    { "<C-n>", false },
    { "<F9>",  "<cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
    { "<F10>", "<cmd>NvimTreeFocus<CR>",  desc = "Focus NvimTree" },
  },
  config = function(_, opts)
    require("nvim-tree").setup(opts)
  end,
}
