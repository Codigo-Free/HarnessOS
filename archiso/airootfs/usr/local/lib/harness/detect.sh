#!/usr/bin/env bash
# HarnessOS — GPU / CPU detection library
# Source this file to get detection functions

detect_gpu_vendor() {
    local pci_output
    pci_output=$(lspci 2>/dev/null || true)

    if echo "${pci_output}" | grep -qi "nvidia"; then
        echo "nvidia"
    elif echo "${pci_output}" | grep -qiE "amd|radeon|advanced micro"; then
        echo "amd"
    elif echo "${pci_output}" | grep -qi "intel.*graphics\|intel.*vga"; then
        echo "intel"
    else
        echo "unknown"
    fi
}

detect_nvidia_model() {
    lspci 2>/dev/null \
        | grep -iE "nvidia" \
        | grep -iE "vga|3d|display" \
        | head -1 \
        | sed 's/.*\[//' \
        | sed 's/\].*//' \
        | xargs
}

get_recommended_nvidia_driver() {
    local gpu_name
    gpu_name=$(detect_nvidia_model | tr '[:upper:]' '[:lower:]')

    # RTX 40xx (Ada Lovelace), RTX 30xx (Ampere), RTX 20xx (Turing), GTX 16xx
    if echo "${gpu_name}" | grep -qE "rtx (40|30|20)|gtx (16|10)"; then
        echo "nvidia-dkms"
    # Kepler / Maxwell (GTX 700/900 series) — needs legacy 470xx driver
    elif echo "${gpu_name}" | grep -qE "gtx (7|9)[0-9]{2}|tesla k|quadro k"; then
        echo "nvidia-470xx-dkms"
    else
        echo "nvidia-dkms"
    fi
}

detect_cpu_count() {
    nproc
}

detect_ram_gb() {
    awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo
}

detect_disk_list() {
    lsblk -d -n -o NAME,SIZE,MODEL \
        | grep -vE "^(sr|loop|zram|ram)" \
        | awk '{print "/dev/"$1, $2, $3}'
}
