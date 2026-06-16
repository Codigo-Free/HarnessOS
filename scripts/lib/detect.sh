#!/usr/bin/env bash
# HarnessOS — Host-side GPU/CPU detection (mirrors airootfs version)

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

is_kvm_available() {
    [[ -r /dev/kvm ]] && echo "true" || echo "false"
}
