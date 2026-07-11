# aliases
alias rb='nh os switch ~/git/dotfiles/nixos'
alias nixedit='nvim ~/git/dotfiles/nixos/configuration.nix'
alias nixflake='nvim ~/git/dotfiles/nixos/flake.nix'
alias nixup="~/git/dotfiles/nixos/scripts/update.sh"
alias cl='clear'
alias ls='eza --icons=always -a'
alias l='ls'
alias ff='fastfetch'
alias af='anifetch ~/nixos-logo.mp4 -W 30 -H 15 -fr -ca "--symbols braille --colors 2 --fg-only" -c ~/.config/fastfetch/anifetch.jsonc'
alias nt='wlctl'
alias spf='superfile'
alias spt='spotify_player'
alias zconf='nvim ~/.zshrc'
alias wtf='tldr'

# zinit
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

zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search

zinit ice wait lucid
zinit light hlissner/zsh-autopair

# options
setopt NOMATCH NOTIFY
unsetopt BEEP
bindkey -v

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# navigation
setopt AUTO_CD AUTO_PUSHD

# editor
export EDITOR=nvim VISUAL=nvim

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# completion
zstyle :compinstall filename '/home/isaac/.zshrc'
autoload -Uz compinit
compinit -C
zinit cdreplay -q

# prompt
eval "$(starship init zsh)"

export PATH="$PATH:/home/isaac/.local/go/bin"

export PATH="$PATH:/home/isaac/go/bin"
