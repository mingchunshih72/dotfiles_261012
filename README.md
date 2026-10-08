# C 開發環境 dotfiles

Ubuntu / Debian / WSL 一鍵安裝：zsh + tmux + Neovim(C IDE) + 編譯工具鏈。

---

## 到新公司怎麼用

```bash
# 1. 把這個 repo 弄到新機器（三種方式選一種）
git clone <你的 repo> ~/dotfiles          # 若已推上 git
# 或 scp 過去：  scp dotfiles.tar.gz user@newhost:~/ && tar -xzf dotfiles.tar.gz
# 或隨身碟：     cp -r /media/usb/dotfiles ~/

# 2. 先看看缺什麼（不動系統）
cd ~/dotfiles && ./install.sh --check

# 3. 安裝
./install.sh

# 4. 重開終端
exec zsh
```

安裝完記得改 git 身分：

```bash
git config --global user.name  "你的名字"
git config --global user.email "你的公司 email"
```

### 其他用法

```bash
./install.sh --check          # 只檢查，不安裝
./install.sh --dry-run        # 只印出會做什麼
./install.sh --no-apt         # 沒有 sudo 時跳過系統套件
./install.sh --only nvim      # 只處理某一塊：apt|zsh|tmux|nvim|git|link
```

> `install.sh` 是**可重複執行**的：既有設定會先備份到 `~/.dotfiles-backup/<時間>/`，
> 已安裝的東西會跳過。

---

## 內容

```
install.sh              主安裝腳本（備份舊設定 → 安裝 → 建 symlink → 驗證）
CHEATSHEET.md           ★ Neovim 快捷鍵總表
packages/apt.txt        apt 套件清單（含每個套件的用途註解）
nvim/                   Neovim 設定（NvChad v2.5 base，C 開發特化）
zsh/zshrc               oh-my-zsh 主設定
zsh/zshrc.dev.zsh       C 開發用的 alias / 函式 / PATH
tmux/tmux.conf          oh-my-tmux 本體（不要改這個）
tmux/tmux.conf.local    tmux 的使用者覆寫（要改設定改這裡）
git/gitconfig           git 設定與 alias
bin/mkidx               建立 cscope.out + tags + compile_commands.json
```

### install.sh 做的事

| 步驟 | 內容 |
|---|---|
| 1 | `apt install` — `packages/apt.txt` 裡的所有套件（含 ripgrep / cscope / ctags / bear） |
| 2 | 連結 `nvim/` → `~/.config/nvim` |
| 3 | 裝 **Neovim ≥ 0.11**（apt 版本太舊，用官方 tarball 裝到 `~/.local/nvim`） |
|   | 再跑 `Lazy! sync` + `TSUpdateSync` + `MasonInstall clangd` |
| 4 | 裝 oh-my-zsh + autosuggestions / syntax-highlighting / completions，`chsh` 設為預設 shell |
| 5 | 連結 tmux 設定、裝 tpm |
| 6 | 連結 gitconfig、把 `bin/` 連到 `~/.local/bin` |
| 7 | 跑環境檢查，列出還缺什麼 |

---

## 開一個 C 專案

```bash
cd ~/work/project
mkidx          # 建索引：cscope.out + tags + compile_commands.json
nvim
```

`mkidx` 做三件事，缺哪個工具就跳過哪一步：

1. `cscope -bqkv` → `cscope.out`（函式呼叫關係查詢）
2. `ctags -R` → `tags`（`<C-]>` 跳轉）
3. `bear -- make` → `compile_commands.json`（**clangd 精準跳轉的關鍵**）

在 nvim 裡也可以：`<Space>mt`（重建索引）、`<Space>mb`（重跑 bear）。

### 為什麼需要 compile_commands.json

clangd 要知道每個 `.c` 是用什麼 `-I` / `-D` 編出來的，才能正確解析 include 與 `#ifdef`。
沒有它，`gd`（跳定義）和 `gr`（找參考）會不準或完全失效。

`bear` 的做法是攔截 `make` 的每一道編譯指令並記錄下來，所以：

```bash
make clean && bear -- make      # 或直接 mkidx
```

交叉編譯（arm-none-eabi-gcc 之類）也適用，`bear` 記什麼就是什麼。
如果專案用 CMake，更簡單：`cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..`。

**萬一 clangd 怎樣都不行**（公司的 toolchain 太特殊），就全部改用 cscope：
`<Space>cg`（找定義）、`<Space>cc`（誰呼叫我）。cscope 只做純文字/語法層分析，
不需要編得起來，對超大型或半殘的專案反而更可靠。

---

## 常用 shell alias / 函式

| 指令 | 功能 |
|---|---|
| `v` / `vi` / `vim` | `nvim` |
| `m` / `mj` / `mc` / `mr` | `make` / `make -j$(nproc)` / `make clean` / clean + make |
| `mb` / `mbc` | `bear -- make` / clean + `bear -- make` |
| `mkidx` | 建立 cscope + ctags + compile_commands.json |
| `cleanidx` | 清掉上面那些索引檔 |
| `fcd` | fzf 選目錄並 cd 過去 |
| `fv` | fzf 選檔案並用 nvim 開 |
| `gs` / `gd` / `gl` | `git status -sb` / `git diff` / 圖形化 log |
| `ta` / `tn` / `tl` | tmux attach / new / list |
| `ll` / `la` | `ls -lh` / `ls -lha` |
| `extract xxx.tar.gz` | 自動判斷格式解壓 |

> `MAKEFLAGS="-j$(nproc)"` 已預設，所以 `make` 本身就是平行編譯。

---

## tmux 常用鍵（prefix 預設 `C-b`）

| 按鍵 | 功能 |
|---|---|
| `prefix` `\|` | 垂直分割（保留當前目錄） |
| `prefix` `-` | 水平分割 |
| `Alt` + 方向鍵 | 切換 pane（不用按 prefix） |
| `prefix` `c` / `n` / `p` | 新視窗 / 下一個 / 上一個 |
| `prefix` `z` | pane 放大 / 還原 |
| `prefix` `[` | 進 copy-mode（`v` 選取、`y` 複製、`Esc` 離開） |
| `prefix` `d` | detach |
| `prefix` `r` | 重載 `~/.tmux.conf` |
| `prefix` `e` | 編輯 `~/.tmux.conf.local` |
| `prefix` `?` | 列出所有鍵位 |

要改 tmux 設定請改 `tmux/tmux.conf.local`，**不要動 `tmux.conf`**（那是 oh-my-tmux 本體）。

---

## 維護

```bash
# 把本機的改動收回 dotfiles
rsync -a --delete --exclude='.git' ~/.config/nvim/ ~/dotfiles/nvim/
cp ~/.zshrc ~/dotfiles/zsh/zshrc
cp ~/.tmux.conf.local ~/dotfiles/tmux/tmux.conf.local
cd ~/dotfiles && git add -A && git commit -m "update" && git push
```

> `install.sh` 建的是 **symlink**，所以改 `~/.config/nvim/*` 等於直接改 `~/dotfiles/nvim/*`，
> 上面的 rsync 只有在你是用 `cp` 而非 symlink 安裝時才需要。

更新外掛：`nvim` 裡 `:Lazy sync`、`:TSUpdate`、`:MasonUpdate`。
plugin 版本鎖在 `nvim/lazy-lock.json`，到新機器會裝到完全一樣的版本。

---

## 快捷鍵

→ **[CHEATSHEET.md](CHEATSHEET.md)**

在 nvim 裡忘記鍵位時：
- 按 `<Space>` 停住 → which-key 列出所有可按的鍵
- `<Space>fk` → 模糊搜尋所有快捷鍵
- `<Space>ch` → NvChad 內建快捷鍵表
