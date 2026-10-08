return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- C 編譯的 fzf 排序器，大專案快非常多
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable "make" == 1 end,
      },
      "nvim-tree/nvim-web-devicons",
    },
    opts = function()
      local nvchad_opts = require "nvchad.configs.telescope"
      local actions = require "telescope.actions"

      nvchad_opts.defaults = vim.tbl_deep_extend("force", nvchad_opts.defaults or {}, {
        path_display = { "truncate" },
        dynamic_preview_title = true,
        -- 全域搜尋忽略這些
        file_ignore_patterns = {
          "%.o$", "%.a$", "%.so$", "%.ko$", "%.obj$", "%.elf$", "%.bin$",
          "%.d$", "%.lo$", "%.la$", "%.swp$",
          "^%.git/", "/%.git/", "node_modules/", "^build/", "/build/",
          "^out/", "%.tar%.gz$", "%.zip$", "tags$", "cscope%.out$",
        },
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading", "--with-filename",
          "--line-number", "--column", "--smart-case", "--hidden",
          "--glob", "!.git/*",
        },
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist, -- 全部丟 quickfix
            ["<C-u>"] = false,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<C-f>"] = actions.preview_scrolling_up,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
      })

      nvchad_opts.pickers = {
        find_files = { hidden = true, follow = true },
        live_grep  = { additional_args = { "--hidden" } },
        buffers    = { sort_mru = true, ignore_current_buffer = true },
      }

      nvchad_opts.extensions = vim.tbl_deep_extend("force", nvchad_opts.extensions or {}, {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      })

      nvchad_opts.extensions_list = { "themes", "terms", "fzf" }
      return nvchad_opts
    end,
  },
}
