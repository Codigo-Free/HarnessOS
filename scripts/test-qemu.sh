#!/usr/bin/env bash
# HarnessOS — QEMU boot test
# Boots the latest ISO in QEMU for quick validation.
# Requires: qemu-system-x86_64, KVM recommended
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
OUT_DIR="${ROOT_DIR}/out"

source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/detect.sh"

ISO=$(find "${OUT_DIR}" -name "*.iso" | sort | tail -1)
[[ -z "${ISO}" ]] && die "No ISO found in ${OUT_DIR}. Build one first with ./scripts/build-docker.sh"

log_step "Booting HarnessOS ISO in QEMU"
log_info "ISO: ${ISO}"

KVM_ARGS=()
if [[ "$(is_kvm_available)" == "true" ]]; then
    KVM_ARGS=(-enable-kvm -cpu host)
    log_info "KVM acceleration: enabled"
else
    log_warn "KVM not available — boot will be slow"
fi

OVMF_PATHS=(
    /usr/share/ovmf/OVMF.fd
    /usr/share/OVMF/OVMF_CODE.fd
    /usr/share/edk2/x64/OVMF.fd
)
BIOS_ARGS=()
for p in "${OVMF_PATHS[@]}"; do
    if [[ -f "${p}" ]]; then
        BIOS_ARGS=(-bios "${p}")
        log_info "UEFI firmware: ${p}"
        break
    fi
done
[[ ${#BIOS_ARGS[@]} -eq 0 ]] && log_info "UEFI firmware: not found — using legacy BIOS"

qemu-system-x86_64 \
    "${KVM_ARGS[@]}" \
    -m 4096 \
    -smp 4 \
    "${BIOS_ARGS[@]}" \
    -drive "file=${ISO},media=cdrom,readonly=on" \
    -boot d \
    -vga virtio \
    -display gtk,zoom-to-fit=on \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -audiodev none,id=noaudio \
    "$@"
