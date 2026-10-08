return {
  {
    "dhananjaylatkar/cscope_maps.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
      -- 已移除 fzf-lua / mini.pick / snacks.nvim：
      -- picker 用 telescope，留著它們只會多出一堆 checkhealth 錯誤與啟動負擔
    },
    opts = {
      disable_maps = false,
      skip_input_prompt = true, -- 直接吃游標下的 <cword>/<cfile>
      prefix = "<leader>c",

      cscope = {
        db_file = "./cscope.out",
        exec = "cscope",
        picker = "telescope",
        picker_opts = { window_size = 12, window_pos = "bottom" },
        skip_picker_for_single_result = true, -- 只有一個結果就直接跳過去
        db_build_cmd = { script = "default", args = { "-bqkv" } },
        statusline_indicator = "cscope",
        project_rooter = {
          enable = true,      -- 往上層目錄自動找 cscope.out（修正：原本 false）
          change_cwd = false,
        },
        tag = {
          keymap = true,      -- 讓 <C-]> / <C-t> 走 cscope -> tag picker -> ctags
          order = { "cs", "tag_picker", "tag" },
          tag_cmd = "tjump",
        },
      },

      stack_view = { tree_hl = true },
    },

    config = function(_, opts)
      require("cscope_maps").setup(opts)

      -- ── 傳統 vim cscope 風格的第二組快捷鍵（<C-\> 開頭） ──
      local map = vim.keymap.set
      local alias = {
        s = "Find this symbol",
        g = "Find global definition",
        c = "Find functions calling this",
        d = "Find functions called by this",
        t = "Find this text string",
        e = "Find this egrep pattern",
        f = "Find this file",
        i = "Find files #including this",
        a = "Find assignments to this symbol",
      }
      for k, desc in pairs(alias) do
        map({ "n", "v" }, "<C-\\>" .. k, "<cmd>CsPrompt " .. k .. "<cr>",
          { silent = true, desc = "cscope: " .. desc })
      end

      -- ── 呼叫關係樹狀圖（stack view） ──────────────────────
      map("n", "<leader>cu", function()
        vim.cmd("CsStackView open up " .. vim.fn.expand "<cword>")
      end, { silent = true, desc = "cscope: 呼叫樹 - 誰呼叫這個函式" })
      map("n", "<leader>cD", function()
        vim.cmd("CsStackView open down " .. vim.fn.expand "<cword>")
      end, { silent = true, desc = "cscope: 呼叫樹 - 這個函式呼叫誰" })
      map("n", "<leader>cv", "<cmd>CsStackView toggle<cr>",
        { silent = true, desc = "cscope: 開/關呼叫樹視窗" })

      -- ══════════════════════════════════════════════════════
      --  :TagsBuild  一次產生 cscope.out + ctags tags
      -- ══════════════════════════════════════════════════════
      local function find_root()
        local hit = vim.fs.find(
          { "cscope.out", "compile_commands.json", "Makefile", "CMakeLists.txt", ".git" },
          { upward = true, path = vim.fn.expand "%:p:h" }
        )[1]
        return hit and vim.fs.dirname(hit) or vim.fn.getcwd()
      end

      vim.api.nvim_create_user_command("TagsBuild", function()
        local root = find_root()
        local missing = {}
        if vim.fn.executable "cscope" == 0 then table.insert(missing, "cscope") end
        if vim.fn.executable "ctags" == 0 then table.insert(missing, "universal-ctags") end
        if #missing > 0 then
          vim.notify("缺少工具： sudo apt install " .. table.concat(missing, " "), vim.log.levels.ERROR)
          return
        end

        local sh = table.concat({
          "set -e",
          "cd " .. vim.fn.shellescape(root),
          -- 1. 收集所有 C/C++ 原始碼清單
          [[find . \( -path ./.git -o -path ./build -o -path ./out -o -path ./node_modules \) -prune -o ]]
            .. [[-type f \( -name '*.c' -o -name '*.h' -o -name '*.cc' -o -name '*.cpp' ]]
            .. [[-o -name '*.cxx' -o -name '*.hpp' -o -name '*.hh' -o -name '*.S' -o -name '*.s' \) ]]
            .. [[-print > cscope.files]],
          -- 2. 建 cscope 資料庫
          "cscope -bqkv -i cscope.files",
          -- 3. 建 ctags
          "ctags -R --c-kinds=+px --c++-kinds=+px --fields=+iaS --extras=+q "
            .. "--exclude=.git --exclude=build --exclude=out -L cscope.files",
        }, "\n")

        vim.notify("建立 cscope.out / tags …\n" .. root, vim.log.levels.INFO)
        vim.fn.jobstart({ "sh", "-c", sh }, {
          on_exit = function(_, code)
            vim.schedule(function()
              if code == 0 then
                local n = #(vim.fn.readfile(root .. "/cscope.files") or {})
                vim.notify(("索引完成：%d 個檔案\n%s"):format(n, root), vim.log.levels.INFO)
                pcall(vim.cmd, "Cs db add " .. root .. "/cscope.out")
              else
                vim.notify("索引失敗 (exit " .. code .. ")", vim.log.levels.ERROR)
              end
            end)
          end,
        })
      end, { desc = "建立 cscope.out 與 ctags tags" })
    end,
  },
}
