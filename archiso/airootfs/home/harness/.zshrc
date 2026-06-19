# HarnessOS — zshrc

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

autoload -Uz compinit && compinit

# Plugins
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Zoxide — smarter cd
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Yazi — file manager with dir-change on exit
function y() {
    local tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
    yazi "$@" --cwd-file="$tmp"
    if [[ -s "$tmp" ]]; then
        local cwd="$(cat "$tmp")"
        [[ "$cwd" != "$PWD" ]] && cd -- "$cwd"
    fi
    rm -f "$tmp"
}

# Aliases — system
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias vim='nvim'

# Aliases — lazy TUI tools
alias lg='lazygit'
alias lzd='lazydocker'
alias top='btm'
alias logs='lnav'
alias k='k9s'

# Aliases — docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Aliases — network
alias ip='ip --color=auto'
alias wifi='nmtui'
