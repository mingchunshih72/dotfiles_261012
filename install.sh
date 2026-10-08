#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  C 開發環境一鍵安裝 (Ubuntu / Debian / WSL)
#
#  用法：
#    ./install.sh                # 全部安裝
#    ./install.sh --no-apt       # 跳過 apt（沒有 sudo 時）
#    ./install.sh --only nvim    # 只裝某一塊: apt|zsh|tmux|nvim|git|link
#    ./install.sh --check        # 只檢查目前環境缺什麼
#    ./install.sh --dry-run      # 只印出會做什麼
# ════════════════════════════════════════════════════════════════
set -uo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=11
NVIM_PREFIX="$HOME/.local/nvim"

DO_APT=1; DO_ZSH=1; DO_TMUX=1; DO_NVIM=1; DO_GIT=1; DO_LINK=1
DRY=0; CHECK_ONLY=0

# ── 顏色 ────────────────────────────────────────────────────────
if [ -t 1 ]; then
  R='\033[31m'; G='\033[32m'; Y='\033[33m'; B='\033[34m'; BD='\033[1m'; N='\033[0m'
else R=''; G=''; Y=''; B=''; BD=''; N=''; fi
info()  { printf "${B}▶${N} %s\n" "$*"; }
ok()    { printf "${G}✔${N} %s\n" "$*"; }
warn()  { printf "${Y}⚠${N} %s\n" "$*"; }
err()   { printf "${R}✖${N} %s\n" "$*" >&2; }
head1() { printf "\n${BD}%s${N}\n%s\n" "$*" "────────────────────────────────────────────────────────"; }
run()   { if [ "$DRY" = 1 ]; then printf "  [dry-run] %s\n" "$*"; else eval "$@"; fi; }

# ── 參數 ────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --no-apt)  DO_APT=0 ;;
    --no-zsh)  DO_ZSH=0 ;;
    --no-tmux) DO_TMUX=0 ;;
    --no-nvim) DO_NVIM=0 ;;
    --dry-run) DRY=1 ;;
    --check)   CHECK_ONLY=1 ;;
    --only)
      shift; DO_APT=0; DO_ZSH=0; DO_TMUX=0; DO_NVIM=0; DO_GIT=0; DO_LINK=0
      case "$1" in
        apt) DO_APT=1 ;; zsh) DO_ZSH=1 ;; tmux) DO_TMUX=1 ;;
        nvim) DO_NVIM=1 ;; git) DO_GIT=1 ;; link) DO_LINK=1 ;;
        *) err "--only 不認得：$1"; exit 1 ;;
      esac ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "不認得的參數：$1"; exit 1 ;;
  esac
  shift
done

# ════════════════════════════════════════════════════════════════
#  環境檢查
# ════════════════════════════════════════════════════════════════
check_env() {
  head1 "環境檢查"
  local miss=0
  printf "  OS     : %s\n" "$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -s)"
  printf "  Kernel : %s\n" "$(uname -r)"
  [ -n "${WSL_DISTRO_NAME:-}" ] && printf "  WSL    : %s\n" "$WSL_DISTRO_NAME"
  echo
  # name:why
  local tools=(
    "git:版本控制" "ssh:遠端" "tar:解壓" "unzip:解壓" "curl:下載"
    "zsh:shell" "tmux:終端分割"
    "gcc:編譯器" "make:建置" "gdb:除錯" "cmake:建置"
    "cscope:★ 函式呼叫關係查詢" "ctags:★ tag 跳轉"
    "rg:★ nvim 全域搜尋 (ripgrep)" "fzf:模糊搜尋"
    "bear:★ 產生 compile_commands.json" "clangd:★ C/C++ LSP"
    "clang-format:格式化" "nvim:編輯器" "node:部分 LSP 需要"
  )
  for t in "${tools[@]}"; do
    local n="${t%%:*}" why="${t#*:}" p
    p="$(command -v "$n" 2>/dev/null || true)"
    # fd 在 Ubuntu 叫 fdfind
    [ -z "$p" ] && [ "$n" = "fd" ] && p="$(command -v fdfind 2>/dev/null || true)"
    # clangd / 其他 LSP 也可能是 mason 裝的（只有 nvim 會用到，不算缺）
    local extra=""
    if [ -z "$p" ] && [ -x "$HOME/.local/share/nvim/mason/bin/$n" ]; then
      p="$HOME/.local/share/nvim/mason/bin/$n"; extra=" (mason)"
    fi
    # 名稱是 ASCII 可以用 %-14s 對齊；中文說明只在「缺少」時才印，避免寬度對不齊
    if [ -n "$p" ]; then
      printf "  ${G}✔${N} %-14s %s%s\n" "$n" "$p" "$extra"
    else
      printf "  ${R}✖${N} %-14s ${Y}缺少${N} — %s\n" "$n" "$why"
      miss=$((miss+1))
    fi
  done
  echo
  if command -v nvim >/dev/null; then
    local v; v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    if nvim_too_old; then
      printf "  ${R}✖${N} Neovim %s 太舊，本設定需要 >= %s.%s\n" "$v" "$NVIM_MIN_MAJOR" "$NVIM_MIN_MINOR"
      miss=$((miss+1))
    else
      printf "  ${G}✔${N} Neovim %s\n" "$v"
    fi
  fi
  [ "$miss" -gt 0 ] && warn "共 $miss 項缺少 — 執行 ./install.sh 即可補齊" || ok "所有工具齊備"
  return 0
}

nvim_too_old() {
  command -v nvim >/dev/null || return 0
  local v maj min
  v="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  maj="${v%%.*}"; min="${v##*.}"
  [ "$maj" -gt "$NVIM_MIN_MAJOR" ] && return 1
  [ "$maj" -eq "$NVIM_MIN_MAJOR" ] && [ "$min" -ge "$NVIM_MIN_MINOR" ] && return 1
  return 0
}

if [ "$CHECK_ONLY" = 1 ]; then check_env; exit 0; fi

# ── 備份並連結 ──────────────────────────────────────────────────
backup_and_link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    ok "已連結 $dst"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    run "mkdir -p '$BACKUP'"
    run "mv '$dst' '$BACKUP/'"
    warn "原本的 $dst 已備份到 $BACKUP/"
  fi
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -sfn '$src' '$dst'"
  ok "連結 $dst -> $src"
}

# ════════════════════════════════════════════════════════════════
#  1. apt 套件
# ════════════════════════════════════════════════════════════════
install_apt() {
  head1 "1/5  安裝 apt 套件"
  if ! command -v apt-get >/dev/null; then warn "不是 apt 系統，跳過"; return; fi
  if ! sudo -n true 2>/dev/null; then
    info "需要 sudo 權限安裝系統套件，請輸入密碼（直接 Ctrl-C 可跳過）"
    if ! sudo -v; then
      warn "沒有 sudo 權限，跳過 apt。請請管理員安裝 packages/apt.txt 裡的套件"
      return
    fi
  fi
  local pkgs
  pkgs="$(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$DOT/packages/apt.txt" | tr -d ' \t' | sort -u | tr '\n' ' ')"
  info "更新套件索引"
  run "sudo apt-get update -qq"
  info "安裝：$(echo "$pkgs" | wc -w) 個套件"
  # 一次裝，失敗就逐一裝（避免一個壞套件卡住全部）
  if ! run "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pkgs"; then
    warn "整批安裝失敗，改成逐一安裝"
    for p in $pkgs; do
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$p" >/dev/null 2>&1 \
        && ok "$p" || warn "$p 安裝失敗（可能該發行版沒有此套件）"
    done
  fi
  # fd-find 的執行檔叫 fdfind，補一個 fd 連結
  if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
    run "mkdir -p '$HOME/.local/bin' && ln -sf \"\$(command -v fdfind)\" '$HOME/.local/bin/fd'"
    ok "建立 fd -> fdfind 連結"
  fi
  run "sudo locale-gen en_US.UTF-8 >/dev/null 2>&1 || true"
  ok "apt 套件完成"
}

# ════════════════════════════════════════════════════════════════
#  2. Neovim（apt 版太舊，用官方 tarball）
# ════════════════════════════════════════════════════════════════
install_nvim_binary() {
  head1 "2/5  安裝 Neovim (>= $NVIM_MIN_MAJOR.$NVIM_MIN_MINOR)"
  if ! nvim_too_old; then
    ok "已有 Neovim $(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')，跳過"
  else
    local arch tgz url tmp
    case "$(uname -m)" in
      x86_64)  arch="x86_64" ;;
      aarch64) arch="arm64" ;;
      *) err "不支援的架構 $(uname -m)，請自行安裝 Neovim >= 0.11"; return 1 ;;
    esac
    tmp="$(mktemp -d)"
    for tgz in "nvim-linux-${arch}.tar.gz" "nvim-linux64.tar.gz"; do
      url="https://github.com/neovim/neovim/releases/latest/download/${tgz}"
      info "下載 $url"
      if [ "$DRY" = 1 ]; then echo "  [dry-run] curl ... $url"; break; fi
      if curl -fsSL --retry 3 -o "$tmp/nvim.tar.gz" "$url"; then break; fi
      warn "$tgz 下載失敗，試下一個檔名"
      url=""
    done
    if [ "$DRY" = 0 ]; then
      [ -s "$tmp/nvim.tar.gz" ] || { err "Neovim 下載失敗"; rm -rf "$tmp"; return 1; }
      rm -rf "$NVIM_PREFIX"; mkdir -p "$NVIM_PREFIX"
      tar -xzf "$tmp/nvim.tar.gz" -C "$NVIM_PREFIX" --strip-components=1
      rm -rf "$tmp"
      mkdir -p "$HOME/.local/bin"
      ln -sf "$NVIM_PREFIX/bin/nvim" "$HOME/.local/bin/nvim"
      export PATH="$NVIM_PREFIX/bin:$HOME/.local/bin:$PATH"
      ok "Neovim $("$NVIM_PREFIX/bin/nvim" --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') 安裝到 $NVIM_PREFIX"
    fi
  fi
}

bootstrap_nvim_plugins() {
  info "安裝 nvim 外掛（lazy.nvim）"
  local NV; NV="$(command -v nvim || echo "$NVIM_PREFIX/bin/nvim")"
  if [ "$DRY" = 1 ]; then echo "  [dry-run] nvim --headless +'Lazy! sync' +qa"; return; fi
  "$NV" --headless "+Lazy! sync" +qa 2>&1 | tail -3
  info "安裝 treesitter parser"
  "$NV" --headless "+TSUpdateSync" +qa 2>&1 | tail -3
  info "用 mason 安裝 clangd"
  "$NV" --headless "+MasonInstall clangd" +qa 2>&1 | tail -3 || warn "mason clangd 安裝失敗（系統 apt 的 clangd 可當備援）"
  ok "nvim 外掛完成"
}

# ════════════════════════════════════════════════════════════════
#  3. zsh + oh-my-zsh
# ════════════════════════════════════════════════════════════════
install_zsh() {
  head1 "3/5  zsh + oh-my-zsh"
  if ! command -v zsh >/dev/null; then err "沒有 zsh，請先跑 apt 那一段"; return 1; fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "安裝 oh-my-zsh"
    run "RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    ok "oh-my-zsh 已安裝"
  fi

  local CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone_plug() {
    local url="$1" dir="$2"
    if [ -d "$dir" ]; then ok "$(basename "$dir") 已安裝"
    else info "安裝 $(basename "$dir")"; run "git clone -q --depth=1 '$url' '$dir'"; fi
  }
  clone_plug https://github.com/zsh-users/zsh-autosuggestions     "$CUSTOM/plugins/zsh-autosuggestions"
  clone_plug https://github.com/zsh-users/zsh-syntax-highlighting "$CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plug https://github.com/zsh-users/zsh-completions         "$CUSTOM/plugins/zsh-completions"

  backup_and_link "$DOT/zsh/zshrc"        "$HOME/.zshrc"
  backup_and_link "$DOT/zsh/zshrc.dev.zsh" "$HOME/.zshrc.dev.zsh"

  # 設為預設 shell
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    info "把預設 shell 改成 zsh（需要輸入密碼）"
    run "chsh -s \"\$(command -v zsh)\"" || warn "chsh 失敗，請手動執行：chsh -s \$(command -v zsh)"
  else
    ok "預設 shell 已是 zsh"
  fi
}

# ════════════════════════════════════════════════════════════════
#  4. tmux (oh-my-tmux)
# ════════════════════════════════════════════════════════════════
install_tmux() {
  head1 "4/5  tmux"
  if ! command -v tmux >/dev/null; then err "沒有 tmux，請先跑 apt 那一段"; return 1; fi
  ok "tmux $(tmux -V | awk '{print $2}')"
  backup_and_link "$DOT/tmux/tmux.conf"       "$HOME/.tmux.conf"
  backup_and_link "$DOT/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
  # tpm（插件管理器，oh-my-tmux 不強制，留著方便日後加）
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "安裝 tpm"
    run "git clone -q --depth=1 https://github.com/tmux-plugins/tpm '$HOME/.tmux/plugins/tpm'"
  fi
}

# ════════════════════════════════════════════════════════════════
#  5. git / nvim 設定連結
# ════════════════════════════════════════════════════════════════
install_git() {
  head1 "5/5  git 設定"
  backup_and_link "$DOT/git/gitconfig" "$HOME/.gitconfig"
  warn "記得到新公司改 git 身分："
  echo "      git config --global user.name  \"你的名字\""
  echo "      git config --global user.email \"你的公司 email\""
}

link_nvim() {
  info "連結 nvim 設定"
  local t="$HOME/.config/nvim"
  if [ ! -L "$t" ] && [ -d "$t/.git" ]; then
    warn "$t 目前是一個 git repo（有自己的 remote）"
    echo "    接下來會把它整個搬到 $BACKUP/ 再換成指向 dotfiles 的 symlink。"
    if [ "$DRY" = 0 ] && [ -t 0 ]; then
      printf "    要繼續嗎？[y/N] "; read -r a
      case "$a" in [yY]*) ;; *) warn "跳過 nvim 設定連結"; return ;; esac
    fi
  fi
  backup_and_link "$DOT/nvim" "$t"
  # bin/ 裡的小工具
  if [ -d "$DOT/bin" ] && [ -n "$(ls -A "$DOT/bin" 2>/dev/null)" ]; then
    run "mkdir -p '$HOME/.local/bin'"
    for f in "$DOT"/bin/*; do run "ln -sf '$f' '$HOME/.local/bin/$(basename "$f")'"; done
  fi
}

# ════════════════════════════════════════════════════════════════
main() {
  printf "${BD}C 開發環境安裝${N}  (dotfiles: %s)\n" "$DOT"
  [ "$DRY" = 1 ] && warn "DRY-RUN 模式，不會真的改東西"

  [ "$DO_APT"  = 1 ] && install_apt
  [ "$DO_LINK" = 1 ] && link_nvim
  [ "$DO_NVIM" = 1 ] && { install_nvim_binary && bootstrap_nvim_plugins; }
  [ "$DO_ZSH"  = 1 ] && install_zsh
  [ "$DO_TMUX" = 1 ] && install_tmux
  [ "$DO_GIT"  = 1 ] && install_git

  check_env

  head1 "完成"
  echo "  1. 重開終端（或 exec zsh）讓 zsh 設定生效"
  echo "  2. 第一次開 nvim 會自動補裝剩下的外掛：nvim"
  echo "  3. 到 C 專案目錄跑 mkidx 建索引（cscope + ctags + compile_commands.json）"
  echo "  4. 快捷鍵對照表：$DOT/CHEATSHEET.md   或在 nvim 裡按 <Space>fk"
  [ -d "$BACKUP" ] && echo "  舊設定備份在：$BACKUP"
  return 0
}
main
exit 0
