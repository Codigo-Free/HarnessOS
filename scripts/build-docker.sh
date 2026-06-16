#!/usr/bin/env bash
# HarnessOS — Docker-based ISO Build
# Works on any Linux host (Ubuntu, Fedora, Mint, etc.) without installing archiso.
# Requires: Docker with --privileged capability
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
OUT_DIR="${ROOT_DIR}/out"

source "${SCRIPT_DIR}/lib/log.sh"

log_step "HarnessOS Docker Build"

command -v docker &>/dev/null || die "Docker not found. Install Docker first."

mkdir -p "${OUT_DIR}"

log_info "Pulling archlinux:latest..."
docker pull archlinux:latest

log_step "Building ISO inside Docker container..."
docker run \
    --rm \
    --privileged \
    --volume "${ROOT_DIR}:/build" \
    --volume "${OUT_DIR}:/build/out" \
    --workdir /build \
    archlinux:latest \
    /bin/bash -c "
        set -euo pipefail
        echo '>>> Updating system and installing archiso...'
        pacman -Sy --noconfirm archiso

        echo '>>> Building ISO...'
        mkarchiso -v -w /tmp/harness-work -o /build/out /build/archiso

        echo '>>> Setting permissions on output...'
        chmod -R a+rw /build/out/
    "

ISO_FILE=$(find "${OUT_DIR}" -name "*.iso" | sort | tail -1)

echo ""
log_step "Build complete!"
log_ok "File: ${ISO_FILE}"
log_ok "Size: $(du -sh "${ISO_FILE}" | cut -f1)"
echo ""
log_info "Flash to USB: sudo dd if=${ISO_FILE} of=/dev/sdX bs=4M status=progress oflag=sync"
log_info "Test in QEMU: ./scripts/test-qemu.sh"
