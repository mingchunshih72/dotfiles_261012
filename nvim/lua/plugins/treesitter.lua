return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- 固定在 master；main 分支 API 完全不同會壞掉
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "master", -- 必須跟 nvim-treesitter 同為 master
      },
    },
    opts = {
      ensure_installed = {
        "c", "cpp", "make", "cmake", "bash", "lua", "luadoc",
        "vim", "vimdoc", "query", "printf", "diff",
        "gitcommit", "gitignore", "json", "yaml", "markdown",
        "markdown_inline", "python", "asm", "doxygen",
      },
      sync_install = false,
      auto_install = false,

      highlight = { enable = true, use_languagetree = true },
      indent = { enable = true, disable = { "c", "cpp" } }, -- C 用 cindent 比較準

      -- ── 語法層逐步擴大選取 ──────────────────────────────
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "gnn",  -- normal: 開始語法選取
          node_incremental  = "<CR>",      -- visual: 外擴一層 (function/block)
          node_decremental  = "<BS>",      -- visual: 縮回一層
          scope_incremental = false,
        },
      },

      -- ── 語法級文字物件 ─────────────────────────────────
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          -- 只列 C 的 query 真正有定義的 capture
          -- （C 沒有 @block.inner / @comment.inner，內層大括號請用內建的 i{ ）
          keymaps = {
            ["af"] = "@function.outer",    -- 整個 function（含簽章與大括號）
            ["if"] = "@function.inner",    -- function 的 body
            ["ac"] = "@class.outer",       -- 整個 struct / union / enum
            ["ic"] = "@class.inner",       -- struct 的欄位部分
            ["ai"] = "@conditional.outer", -- 整個 if / switch
            ["ii"] = "@conditional.inner", -- if 的條件式
            ["al"] = "@loop.outer",        -- 整個 for / while / do
            ["il"] = "@loop.inner",        -- 迴圈 body
            ["aa"] = "@parameter.outer",   -- 一個參數（含逗號）
            ["ia"] = "@parameter.inner",   -- 參數本身
            ["ab"] = "@block.outer",       -- { ... } 區塊
            ["am"] = "@call.outer",        -- 一個函式呼叫 foo(a, b)
            ["a/"] = "@comment.outer",     -- 整段註解
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start     = {
            ["]f"] = "@function.outer", ["]b"] = "@block.outer",
            ["]i"] = "@conditional.outer", ["]l"] = "@loop.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer", ["[b"] = "@block.outer",
            ["[i"] = "@conditional.outer", ["[l"] = "@loop.outer",
          },
          goto_next_end       = { ["]F"] = "@function.outer" },
          goto_previous_end   = { ["[F"] = "@function.outer" },
        },
        swap = {
          enable = true,
          swap_next     = { ["<leader>sa"] = "@parameter.inner" },
          swap_previous = { ["<leader>sA"] = "@parameter.inner" },
        },
      },
    },
    config = function(_, opts)
      pcall(function()
        dofile(vim.g.base46_cache .. "syntax")
        dofile(vim.g.base46_cache .. "treesitter")
      end)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
