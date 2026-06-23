#!/usr/bin/env bash
# HarnessOS — Security profile setup
set -euo pipefail

echo "Security profile ready."
echo "  nmap -sV <target>      — port scan"
echo "  wireshark              — packet capture"
echo "  hashcat -h             — password recovery"
