#!/usr/bin/env bash
# HarnessOS — Post-install smoke test
# Validates that all expected tools exist in the installed system.
set -euo pipefail

PASS=0
FAIL=0

assert_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  ✓  $1"
        ((PASS++))
    else
        echo "  ✗  $1 NOT FOUND"
        ((FAIL++))
    fi
}

assert_service() {
    if systemctl is-enabled "$1" &>/dev/null; then
        echo "  ✓  $1 (enabled)"
        ((PASS++))
    else
        echo "  ✗  $1 NOT enabled"
        ((FAIL++))
    fi
}

echo "=== HarnessOS Post-Install Smoke Tests ==="
echo ""
echo "--- Shell & Tools ---"
assert_cmd zsh
assert_cmd starship
assert_cmd git
assert_cmd gh
assert_cmd nvim
assert_cmd fzf
assert_cmd rg
assert_cmd fd
assert_cmd bat
assert_cmd eza
assert_cmd zoxide
assert_cmd lazygit
assert_cmd stow
assert_cmd tmux
assert_cmd jq
assert_cmd htop

echo ""
echo "--- Languages ---"
assert_cmd python3
assert_cmd pip
assert_cmd pipx
assert_cmd uv
assert_cmd node
assert_cmd npm
assert_cmd pnpm
assert_cmd tsc
assert_cmd dotnet
assert_cmd java
assert_cmd mvn
assert_cmd php
assert_cmd composer

echo ""
echo "--- AI Tools ---"
assert_cmd claude
assert_cmd ollama

echo ""
echo "--- Container Infra ---"
assert_cmd docker
assert_cmd docker-compose

echo ""
echo "--- Desktop (Hyprland) ---"
assert_cmd Hyprland
assert_cmd waybar
assert_cmd kitty
assert_cmd wofi
assert_cmd grim
assert_cmd slurp

echo ""
echo "--- Services ---"
assert_service NetworkManager
assert_service docker
assert_service ollama
assert_service bluetooth

echo ""
echo "--- Version Checks ---"
python3 -c "import sys; assert sys.version_info >= (3, 11), f'Python too old: {sys.version}'" && echo "  ✓  python3 >= 3.11" || echo "  ✗  python3 version check failed"
node --version | grep -qE "^v(18|20|22)" && echo "  ✓  node.js LTS" || echo "  ✗  node.js version check failed"

echo ""
echo "==================================="
echo "  PASSED: ${PASS}  FAILED: ${FAIL}"
echo "==================================="
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
