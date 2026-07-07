# ── aliases ────────────────────────────────────────────────────────────────
alias rb='nh os switch /etc/nixos'
alias nixedit='sudoedit /etc/nixos/configuration.nix'
alias nixflake='sudoedit /etc/nixos/flake.nix'
alias cl='clear'
alias ls='eza --icons=always -a'
alias l='ls'
alias ff='fastfetch'
alias spf='superfile'
alias spt='spotify_player'
alias zconf='nvim .zshrc'
alias wtf='tldr'

# ── zinit bootstrap ────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit ice wait lucid blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# ── options ────────────────────────────────────────────────────────────────
setopt NOMATCH
setopt NOTIFY
unsetopt BEEP
bindkey -v

# ── history ────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# ── navigation ─────────────────────────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD

# ── editor ─────────────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
