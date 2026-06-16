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
# STARSHIP PROMPT
# ---------------------------------------------------------------------------
command -v starship &>/dev/null && eval "$(starship init zsh)"
