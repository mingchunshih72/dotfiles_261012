# Neovim 設定（NvChad v2.5 base，C 開發用）

```
init.lua                 進入點
lua/options.lua          編輯器選項（搜尋、縮排、顯示…）
lua/autocmds.lua         自動指令（行尾空白、filetype 縮排、回到上次位置…）
lua/mappings.lua         所有自訂快捷鍵
lua/chadrc.lua           NvChad 主題設定
lua/plugins/
  lsp.lua                mason + nvim-lspconfig + trouble
  treesitter.lua         語法高亮 + 語法級文字物件
  telescope.lua          搜尋（fzf-native、ripgrep 參數、ignore 規則）
  cscope.lua             cscope_maps + :TagsBuild
  editing.lua            多光標 / surround / easy-align / todo-comments
  neovim-tree.lua        檔案樹
  conform.lua            格式化（clang-format / stylua / shfmt）
  ui.lua                 bg.nvim / dressing
lua/configs/
  lsp.lua                clangd 設定 + :CcJson / :CcFlags
  conform.lua            formatter 細節
  neovim-tree.lua        檔案樹細節
  lazy.lua               lazy.nvim 設定
CHEATSHEET.md            ★ 快捷鍵總表
```

## 外部指令依賴

| 指令 | 沒有會怎樣 |
|---|---|
| `rg` (ripgrep) | `<Space>fw` 全域搜尋完全失效 |
| `cscope` | `<Space>c*` 全部失效 |
| `ctags` | `<C-]>` tag 跳轉失效 |
| `bear` | 產不出 `compile_commands.json`，clangd 跳轉不準 |
| `clangd` | 沒有 LSP（`gd` / `gr` / 補全 / 診斷） |
| `clang-format` | `<Space>lf` 格式化失效 |
| `make` / `gcc` | `<Space>mm` 編譯失效 |

一次補齊：`sudo apt install ripgrep cscope universal-ctags bear clangd clang-format build-essential`

## 自訂指令

| 指令 | 功能 |
|---|---|
| `:TagsBuild` | 建 `cscope.out` + `tags` |
| `:CcJson [target]` | `bear -- make` 產生 `compile_commands.json` 並重啟 LSP |
| `:CcFlags` | 產生 `compile_flags.txt`（沒 bear 時的後備） |
| `:checkhealth` | 健康檢查 |
| `:Lazy` | 外掛管理 |
| `:Mason` | LSP / 工具安裝 |
