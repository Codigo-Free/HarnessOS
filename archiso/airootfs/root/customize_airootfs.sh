#!/usr/bin/env bash
# HarnessOS — Post-build customization hook
# This script runs inside the chroot of the live environment during ISO build.
# IMPORTANT: runs as root inside the squashfs chroot.
set -euo pipefail

echo ">>> HarnessOS: customize_airootfs.sh starting..."

# ---------------------------------------------------------------------------
# LOCALE
# ---------------------------------------------------------------------------
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# ---------------------------------------------------------------------------
# SHELL — set zsh as default for root
# ---------------------------------------------------------------------------
chsh -s /bin/zsh root

# ---------------------------------------------------------------------------
# SERVICES
# ---------------------------------------------------------------------------
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable docker.service
systemctl enable ollama.service
systemctl enable harness-firstboot.service

# Disable conflicting network services
systemctl disable dhcpcd.service 2>/dev/null || true

# ---------------------------------------------------------------------------
# JOURNALD — reduce console noise
# ---------------------------------------------------------------------------
sed -i 's/#SystemMaxUse=/SystemMaxUse=200M/' /etc/systemd/journald.conf

# ---------------------------------------------------------------------------
# NODE.JS / NPM GLOBAL TOOLS
# ---------------------------------------------------------------------------
# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# pnpm — modern package manager
npm install -g pnpm

# TypeScript tools
npm install -g typescript ts-node tsx

# ---------------------------------------------------------------------------
# PYTHON TOOLS via pipx
# ---------------------------------------------------------------------------
pipx ensurepath || true
pipx install uv || true

# ---------------------------------------------------------------------------
# GH COPILOT EXTENSION
# ---------------------------------------------------------------------------
# Requires gh auth — will be configured post-install by the user
# Pre-install extension binary for offline use
gh extension install github/gh-copilot 2>/dev/null || true

# ---------------------------------------------------------------------------
# DOCKER GROUP — ensure docker group exists
# ---------------------------------------------------------------------------
groupadd -f docker

# ---------------------------------------------------------------------------
# SUDOERS PERMISSIONS
# ---------------------------------------------------------------------------
chmod 440 /etc/sudoers.d/wheel

# ---------------------------------------------------------------------------
# ASCII LOGO
# ---------------------------------------------------------------------------
cat > /usr/local/share/harness/ascii-logo.txt << 'LOGO'

  ██╗  ██╗ █████╗ ██████╗ ███╗   ██╗███████╗███████╗███████╗
  ██║  ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝██╔════╝
  ███████║███████║██████╔╝██╔██╗ ██║█████╗  ███████╗███████╗
  ██╔══██║██╔══██║██╔══██╗██║╚██╗██║██╔══╝  ╚════██║╚════██║
  ██║  ██║██║  ██║██║  ██║██║ ╚████║███████╗███████║███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝
                  AI-Powered Development OS
                  github.com/Codigo-Free/HarnessOS

LOGO

echo ">>> HarnessOS: customize_airootfs.sh done."
