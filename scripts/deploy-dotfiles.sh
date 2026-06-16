#!/usr/bin/env bash
# HarnessOS — Deploy dotfiles via GNU Stow
# Run this after cloning the repo to link all dotfiles into $HOME.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
DOTFILES_DIR="${ROOT_DIR}/dotfiles"

source "${SCRIPT_DIR}/lib/log.sh"

PACKAGES=(zsh hyprland waybar kitty wofi nvim git)

log_step "Deploying HarnessOS dotfiles"
log_info "Source: ${DOTFILES_DIR}"
log_info "Target: ${HOME}"

command -v stow &>/dev/null || die "stow not found. Install it: sudo pacman -S stow"

for pkg in "${PACKAGES[@]}"; do
    if [[ -d "${DOTFILES_DIR}/${pkg}" ]]; then
        log_info "Stowing ${pkg}..."
        stow --dir="${DOTFILES_DIR}" --target="${HOME}" --restow "${pkg}"
        log_ok "${pkg} deployed"
    else
        log_warn "${pkg} directory not found, skipping"
    fi
done

echo ""
log_step "Dotfiles deployed!"
log_info "Start Hyprland: exec Hyprland"
log_info "Reload zsh    : source ~/.zshrc"
