#!/usr/bin/env bash
# HarnessOS — DevOps profile setup
set -euo pipefail

echo "Installing kubectl plugins via krew..."
if command -v kubectl &>/dev/null; then
    kubectl krew install ctx ns neat 2>/dev/null || true
fi

echo "DevOps profile ready."
echo "  terraform init         — initialize Terraform"
echo "  ansible --version      — verify Ansible"
echo "  helm version           — verify Helm"
