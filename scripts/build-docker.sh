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

# Copy installer into airootfs before building
log_step "Injecting installer into airootfs..."
INSTALLER_TARGET="${ROOT_DIR}/archiso/airootfs/usr/local/lib/harness/installer"
rm -rf "${INSTALLER_TARGET}"
mkdir -p "${INSTALLER_TARGET}"
cp -r "${ROOT_DIR}/installer/harness_installer" "${INSTALLER_TARGET}/"
cp    "${ROOT_DIR}/installer/requirements.txt"   "${INSTALLER_TARGET}/"
log_ok "Installer injected"

# Copy galago into airootfs (easter egg, git submodule)
log_step "Injecting galago into airootfs..."
[[ -f "${ROOT_DIR}/galago/galago.py" ]] || die "galago/ submodule is empty — run: git submodule update --init"
GALAGO_TARGET="${ROOT_DIR}/archiso/airootfs/usr/local/share/harness/easter-egg/galago"
rm -rf "${GALAGO_TARGET}"
mkdir -p "${GALAGO_TARGET}"
cp -r "${ROOT_DIR}/galago/galago.py" "${ROOT_DIR}/galago/src" "${ROOT_DIR}/galago/assets" "${GALAGO_TARGET}/"
find "${GALAGO_TARGET}" -name '__pycache__' -exec rm -rf {} +
log_ok "Galago injected"

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
