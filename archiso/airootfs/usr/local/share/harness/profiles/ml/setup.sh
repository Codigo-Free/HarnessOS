#!/usr/bin/env bash
# HarnessOS — ML profile setup
set -euo pipefail

echo "Installing Python ML tools via pip..."
pip install --break-system-packages huggingface-hub transformers accelerate \
    datasets evaluate tokenizers sentencepiece 2>/dev/null || true

echo "Installing Jupyter extensions..."
pip install --break-system-packages jupyterlab ipywidgets 2>/dev/null || true

echo "ML profile ready."
echo "  jupyter notebook       — start Jupyter"
echo "  python -c 'import torch; print(torch.cuda.is_available())'  — test CUDA"
