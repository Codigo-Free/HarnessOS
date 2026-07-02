# HarnessOS — ZSH Configuration

# ---------------------------------------------------------------------------
# HISTORY
# ---------------------------------------------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${HOME}/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# ---------------------------------------------------------------------------
# OPTIONS
# ---------------------------------------------------------------------------
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT
setopt INTERACTIVE_COMMENTS

# ---------------------------------------------------------------------------
# COMPLETIONS
# ---------------------------------------------------------------------------
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# ---------------------------------------------------------------------------
# PLUGINS (system-installed)
# ---------------------------------------------------------------------------
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# History substring search keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ---------------------------------------------------------------------------
# FZF
# ---------------------------------------------------------------------------
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]]    && source /usr/share/fzf/completion.zsh

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"

# ---------------------------------------------------------------------------
# ZOXIDE (smart cd)
# ---------------------------------------------------------------------------
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# ALIASES — Core
# ---------------------------------------------------------------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias lt='eza -la --tree --level=2 --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'

# ---------------------------------------------------------------------------
# ALIASES — Git
# ---------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias lg='lazygit'

# ---------------------------------------------------------------------------
# ALIASES — Docker
# ---------------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias di='docker images'
alias dex='docker exec -it'

# ---------------------------------------------------------------------------
# ALIASES — Python
# ---------------------------------------------------------------------------
alias py='python3'
alias venv='python3 -m venv .venv && source .venv/bin/activate && echo "venv activated"'
alias activate='source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null || echo "No venv found"'
alias pip='python3 -m pip'

# ---------------------------------------------------------------------------
# ALIASES — Node.js / Frontend
# ---------------------------------------------------------------------------
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias nrb='npm run build'
alias nrd='npm run dev'
alias nrt='npm run test'
alias pni='pnpm install'
alias pnr='pnpm run'

# ---------------------------------------------------------------------------
# ALIASES — AI Tools
# ---------------------------------------------------------------------------
alias ai='claude'
alias ollama-pull='ollama pull'

# ---------------------------------------------------------------------------
# ALIASES — Navigation
# ---------------------------------------------------------------------------
alias cdp='cd ~/projects 2>/dev/null || cd ~'
alias cdd='cd ~/dotfiles 2>/dev/null || cd ~'

# ---------------------------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------------------------

# Create and enter directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Quick project init with git + venv
project-init() {
    local name="${1:?Usage: project-init <name>}"
    mkdir -p "${name}" && cd "${name}"
    git init
    echo "# ${name}" > README.md
    echo ".venv/" > .gitignore
    echo "__pycache__/" >> .gitignore
    echo "node_modules/" >> .gitignore
    echo "dist/" >> .gitignore
    echo ".env" >> .gitignore
    git add . && git commit -m "chore: initial project setup"
    echo "Project '${name}' initialized."
}

# ---------------------------------------------------------------------------
# HARNESS AI — shell integration
#   wtf            → diagnose the last failed command with the local AI
#   ask <pregunta> → one-shot answer with system context
#   Ctrl+X Ctrl+A  → explain the command typed at the prompt (keeps your input)
# ---------------------------------------------------------------------------
if command -v harness-ai &>/dev/null; then
    autoload -Uz add-zsh-hook
    typeset -g _harness_last_cmd='' _harness_last_status=0

    _harness_ai_preexec() { _harness_last_cmd="$1"; }
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

# ---------------------------------------------------------------------------
# STARSHIP PROMPT
# ---------------------------------------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"
