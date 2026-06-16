# HarnessOS — ZSH environment (loaded for all sessions, including non-interactive)
export ZDOTDIR="${HOME}"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export MANPAGER="nvim +Man!"

export PIPX_HOME="${HOME}/.local/pipx"
export PIPX_BIN_DIR="${HOME}/.local/bin"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export JAVA_HOME="/usr/lib/jvm/default"
export NODE_ENV=development
export NPM_CONFIG_UPDATE_NOTIFIER=false
export NPM_CONFIG_PREFIX="${HOME}/.npm-global"

export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:${HOME}/.cargo/bin:${JAVA_HOME}/bin:${PATH}"
