# aliases
alias cl='clear'
eval "$(zoxide init zsh)"

alias ls='eza --icons=always -a'
alias l='ls'
alias ff='fastfetch'
alias orb="$HOME/dotfiles/scripts/orb"
alias af='anifetch "$HOME/.config/fastfetch/orb.mp4" -W 50 -H 25 -r 15 -pr 15 -ca "--symbols braille --colors 2 --bg #0f0f0f --preprocess off --dither none --fg-only" -c "$HOME/.config/fastfetch/anifetch.jsonc" --center --no-input-restore'
alias nt='wlctl'
alias md='glow'
alias lg='lazygit'
alias testnet='curl -4 -IsS --max-time 10 https://example.com | head'
alias spt='spotify_player'
alias zconf='nvim ~/.zshrc'
alias reload='source ~/.zshrc'
alias wtf='tldr'
alias lc='z $(find * -type d | fzf)'

# tailscale
export TAILTUI_THEME="$HOME/.config/tailtui/tailtui.toml"
alias tsui='tailtui'

# arch maintenance tui
alias maint='arch-maintenance-tui'

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

zinit ice lucid
zinit light hlissner/zsh-autopair

# keep suggestions synchronous: they must register zle widgets in every shell,
# including a freshly opened terminal. the muted gray matches the monochrome ui.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
zinit ice lucid
zinit light zsh-users/zsh-autosuggestions

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

# local tools and runtimes
export PATH="$HOME/.local/bin:$PATH"
alias hyprctl="$HOME/dotfiles/scripts/hyprctl"
alias tuxedo-pull='tuxedo-todoist-sync pull --file "$HOME/Documents/todo/todo.txt" --apply'
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# completion
zstyle :compinstall filename '/home/isaac/.zshrc'
autoload -Uz compinit
compinit -C
zinit cdreplay -q

# prompt
eval "$(starship init zsh)"

if [[ -r "$HOME/.config/todoist/token" ]]; then
  export TODOIST_API_TOKEN="$(<"$HOME/.config/todoist/token")"
fi

export PATH="$PATH:/home/isaac/.local/go/bin"

export PATH="$PATH:/home/isaac/go/bin"

export PATH=$PATH:~/.cargo/bin

. "$HOME/.local/share/../bin/env"

# bun completions
[ -s "/home/isaac/.bun/_bun" ] && source "/home/isaac/.bun/_bun"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
source /home/isaac/.local/share/leaf/completions/_leaf

# atuin history and shell hooks
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
  bindkey -M emacs '^h' atuin-search
  bindkey -M viins '^h' atuin-search-viins
  bindkey -M vicmd '^h' atuin-search-vicmd
fi
