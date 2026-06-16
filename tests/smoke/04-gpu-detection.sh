#!/usr/bin/env bash
# HarnessOS — GPU validation test
# Pass "nvidia" or "amd" as argument to test GPU-specific features.
set -euo pipefail

GPU_TYPE="${1:-detect}"
PASS=0
FAIL=0

check() {
    local desc="$1"; shift
    if "$@" &>/dev/null; then
        echo "  ✓  ${desc}"
        ((PASS++))
    else
        echo "  ✗  ${desc}"
        ((FAIL++))
    fi
}

echo "=== HarnessOS GPU Validation ==="
echo "GPU type: ${GPU_TYPE}"
echo ""

if [[ "${GPU_TYPE}" == "nvidia" ]]; then
    echo "--- NVIDIA Tests ---"
    check "nvidia-smi works"          nvidia-smi
    check "nvcc (CUDA) available"     nvcc --version
    check "Docker GPU access"         docker run --rm --gpus all nvidia/cuda:12.3.0-base-ubuntu22.04 nvidia-smi
    check "Ollama inference (nvidia)" bash -c 'echo "Say hello" | ollama run llama3.2 2>/dev/null | grep -qi hello'
elif [[ "${GPU_TYPE}" == "amd" ]]; then
    echo "--- AMD Tests ---"
    check "vulkaninfo available"  vulkaninfo --summary
    check "vainfo available"      vainfo
else
    echo "--- Generic Tests ---"
    check "GPU detection script"  /usr/local/bin/harness-detect-gpu
fi

echo ""
echo "--- Ollama (CPU fallback) ---"
check "Ollama service running"   systemctl is-active ollama

echo ""
echo "================================"
echo "  PASSED: ${PASS}  FAILED: ${FAIL}"
echo "================================"
[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
