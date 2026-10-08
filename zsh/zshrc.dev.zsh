# ════════════════════════════════════════════════════════════════
#  C 開發用的環境設定（由 ~/.zshrc 最後 source 進來）
#  不想要某一段就直接註解掉
# ════════════════════════════════════════════════════════════════

# ── PATH ────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
# Neovim（install.sh 預設裝到 ~/.local/nvim）
[ -d "$HOME/.local/nvim/bin" ] && export PATH="$HOME/.local/nvim/bin:$PATH"

# ── 編輯器 ──────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim +Man!'

# ── 語系（避免 make / gcc 輸出亂碼）─────────────────────────────
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# ── 編譯 ────────────────────────────────────────────────────────
export MAKEFLAGS="-j$(nproc)"          # make 預設吃滿所有核心
export CFLAGS="-Wall -Wextra -g -O0"
export HISTSIZE=50000
export SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS

# ── alias：基本 ─────────────────────────────────────────────────
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# fd-find 在 Ubuntu 的執行檔叫 fdfind
command -v fdfind >/dev/null && ! command -v fd >/dev/null && alias fd='fdfind'

# ── alias：git ──────────────────────────────────────────────────
alias gs='git status -sb'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git lg'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'

# ── alias：編譯 ─────────────────────────────────────────────────
alias m='make'
alias mc='make clean'
alias mj='make -j$(nproc)'
alias mr='make clean && make'
# 用 bear 攔截 make 產生 compile_commands.json（clangd 跳轉的關鍵）
alias mb='bear -- make'
alias mbc='make clean && bear -- make'

# ── alias：tmux ─────────────────────────────────────────────────
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'

# ════════════════════════════════════════════════════════════════
#  函式工具
# ════════════════════════════════════════════════════════════════

# mkidx：在當前目錄建立 cscope.out + tags + compile_commands.json
mkidx() {
  local root="${1:-.}"
  echo "▶ 收集原始碼清單 ..."
  find "$root" \( -path '*/.git' -o -path '*/build' -o -path '*/out' -o -path '*/node_modules' \) -prune -o \
       -type f \( -name '*.c' -o -name '*.h' -o -name '*.cc' -o -name '*.cpp' \
                  -o -name '*.cxx' -o -name '*.hpp' -o -name '*.hh' -o -name '*.S' \) \
       -print > cscope.files
  echo "  共 $(wc -l < cscope.files) 個檔案"

  if command -v cscope >/dev/null; then
    echo "▶ 建 cscope.out ..."; cscope -bqkv -i cscope.files
  else
    echo "  ⚠ 沒有 cscope，跳過"
  fi

  if command -v ctags >/dev/null; then
    echo "▶ 建 tags ..."
    ctags -R --c-kinds=+px --c++-kinds=+px --fields=+iaS --extras=+q -L cscope.files
  else
    echo "  ⚠ 沒有 ctags，跳過"
  fi

  if [ -f Makefile ] && command -v bear >/dev/null; then
    echo "▶ 建 compile_commands.json（bear -- make）..."
    make clean >/dev/null 2>&1
    bear -- make >/dev/null 2>&1 && echo "  完成" || echo "  ⚠ bear -- make 失敗，請手動跑看錯誤"
  fi
  echo "✔ 索引完成"
}

# cleanidx：清掉索引檔
cleanidx() { rm -f cscope.* tags compile_commands.json compile_flags.txt && echo "✔ 索引已清除"; }

# fcd：用 fzf 跳目錄
fcd() {
  local dir
  dir=$(find "${1:-.}" -path '*/.git' -prune -o -type d -print 2>/dev/null | fzf +m) && cd "$dir"
}

# fv：用 fzf 選檔案後開 nvim
fv() {
  local f
  f=$(rg --files 2>/dev/null || find . -type f) 
  f=$(echo "$f" | fzf -m --preview 'head -200 {}') && nvim ${f}
}

# ── fzf 整合（有裝才啟用）───────────────────────────────────────
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS='--height 45% --layout=reverse --border --info=inline'
  command -v rg >/dev/null && export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ]   && source /usr/share/doc/fzf/examples/completion.zsh
  [ -f /usr/share/zsh/vendor-completions/_fzf ] || true
fi
