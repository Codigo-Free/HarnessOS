#!/usr/bin/env bash
# HarnessOS — System-wide PATH and environment configuration

# pipx / uv tools
export PIPX_HOME="${HOME}/.local/pipx"
export PIPX_BIN_DIR="${HOME}/.local/bin"
export UV_CACHE_DIR="${HOME}/.cache/uv"
export PATH="${PATH}:${HOME}/.local/bin"

# Cargo / Rust tools
export PATH="${PATH}:${HOME}/.cargo/bin"

# npm global bin
export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
export PATH="${PATH}:${HOME}/.npm-global/bin"
export NPM_CONFIG_UPDATE_NOTIFIER=false

# Java
export JAVA_HOME="/usr/lib/jvm/default"
export PATH="${PATH}:${JAVA_HOME}/bin"

# .NET — disable telemetry
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

# Node
export NODE_ENV=development

# XDG Base Dirs
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
