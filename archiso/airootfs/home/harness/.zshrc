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

# ---------------------------------------------------------------------------
# Harness AI — shell integration
#   wtf            → diagnose the last failed command with the local AI
#   ask <pregunta> → one-shot answer with system context
#   Ctrl+X Ctrl+A  → explain the command typed at the prompt (keeps your input)
# ---------------------------------------------------------------------------
if command -v harness-ai &>/dev/null; then
    autoload -Uz add-zsh-hook
    typeset -g _harness_last_cmd='' _harness_last_status=0

    # Never record wtf itself, or it would overwrite the command it must diagnose
    _harness_ai_preexec() { [[ "$1" == wtf || "$1" == wtf\ * ]] || _harness_last_cmd="$1"; }
    _harness_ai_precmd() {
        local st=$?
        [[ -n "$_harness_last_cmd" ]] || return 0
        _harness_last_status=$st
        # Hint only on "real" failures: skip 0, grep-style 1, Ctrl+C (130), SIGPIPE (141)
        if (( st != 0 && st != 1 && st != 130 && st != 141 )); then
            print -P "%F{240}↯ exit ${st} — escribe 'wtf' para diagnóstico con IA%f"
        fi
    }
    add-zsh-hook preexec _harness_ai_preexec
    add-zsh-hook precmd  _harness_ai_precmd

    wtf() {
        [[ -n "$_harness_last_cmd" ]] || { echo "wtf: no hay comando previo"; return 1; }
        harness-ai doctor -q "The shell command \`${_harness_last_cmd}\` just exited with status ${_harness_last_status}. Diagnose the most likely cause on this machine and give the exact fix."
    }

    ask() { harness-ai -q "$*"; }

    _harness_ai_explain_widget() {
        [[ -n "$BUFFER" ]] || return 0
        zle push-input
        BUFFER="harness-ai --explain ${(q)BUFFER}"
        zle accept-line
    }
    zle -N _harness_ai_explain_widget
    bindkey '^X^A' _harness_ai_explain_widget
fi
