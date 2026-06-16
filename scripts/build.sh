#!/usr/bin/env bash
# HarnessOS — ISO Build Script
# Requires: archiso package, Arch Linux host, root/sudo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
PROFILE_DIR="${ROOT_DIR}/archiso"
OUT_DIR="${ROOT_DIR}/out"
WORK_DIR="${ROOT_DIR}/work"

source "${SCRIPT_DIR}/lib/log.sh"

log_step "HarnessOS ISO Build"
log_info "Profile : ${PROFILE_DIR}"
log_info "Output  : ${OUT_DIR}"
log_info "Work dir: ${WORK_DIR}"
echo ""

# Require root
if [[ $EUID -ne 0 ]]; then
    die "Build requires root. Run: sudo ./scripts/build.sh"
fi

# Check archiso is installed
command -v mkarchiso &>/dev/null || die "archiso not found. Install it: pacman -S archiso"

# Clean previous work dir (keep out/)
if [[ -d "${WORK_DIR}" ]]; then
    log_info "Cleaning previous work directory..."
    rm -rf "${WORK_DIR}"
fi

mkdir -p "${OUT_DIR}" "${WORK_DIR}"

# Copy installer into airootfs so harness-install can find it at runtime
log_step "Injecting installer into airootfs..."
INSTALLER_TARGET="${PROFILE_DIR}/airootfs/usr/local/lib/harness/installer"
rm -rf "${INSTALLER_TARGET}"
mkdir -p "${INSTALLER_TARGET}"
cp -r "${ROOT_DIR}/installer/harness_installer" "${INSTALLER_TARGET}/"
cp    "${ROOT_DIR}/installer/requirements.txt"   "${INSTALLER_TARGET}/"
log_ok "Installer injected at ${INSTALLER_TARGET}"

log_step "Running mkarchiso..."
mkarchiso -v \
    -w "${WORK_DIR}" \
    -o "${OUT_DIR}" \
    "${PROFILE_DIR}"

ISO_FILE=$(find "${OUT_DIR}" -name "*.iso" -newer "${PROFILE_DIR}/profiledef.sh" | sort | tail -1)

if [[ -z "${ISO_FILE}" ]]; then
    die "Build completed but no ISO file found in ${OUT_DIR}"
fi

echo ""
log_step "Build complete!"
log_ok "File: ${ISO_FILE}"
log_ok "Size: $(du -sh "${ISO_FILE}" | cut -f1)"
echo ""
log_info "Flash to USB: sudo dd if=${ISO_FILE} of=/dev/sdX bs=4M status=progress oflag=sync"
log_info "Test in QEMU: ./scripts/test-qemu.sh"
