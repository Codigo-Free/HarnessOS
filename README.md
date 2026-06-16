# HarnessOS

**Arch Linux-based distro for AI-powered software development.**

[![Build ISO](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml)
[![Latest Release](https://img.shields.io/github/v/release/Codigo-Free/HarnessOS)](https://github.com/Codigo-Free/HarnessOS/releases)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

> Ships with Claude CLI, GitHub Copilot, Ollama, Hyprland, Docker, and a complete dev stack — ready in minutes, not hours.

---

## What ships out of the box

| Tool | Purpose |
|------|---------|
| **Claude CLI** (`claude`) | AI pair programmer (Anthropic) |
| **Ollama** | Run LLMs locally (llama3.2, mistral, etc.) |
| **GitHub Copilot** | `gh copilot suggest` + Neovim plugin |
| **Hyprland** | Fast, tiling Wayland compositor |
| **Waybar** | Status bar with Ollama status indicator |
| **Kitty** | GPU-accelerated terminal (Tokyo Night) |
| **Neovim** | Pre-configured with LSP, Copilot, Treesitter |
| **Docker + Compose** | Containerization ready |
| **Python 3** | + pip, pipx, uv, virtualenv |
| **Node.js LTS** | + npm, pnpm, TypeScript, ts-node |
| **.NET SDK** | C# development |
| **OpenJDK** | Java + Maven |
| **PHP + Composer** | Web backend |
| **linux-zen kernel** | Lower latency for desktop workloads |
| **BTRFS + snapper** | Automatic rollback snapshots on every update |

---

## Quick Install

```bash
# 1. Download the latest ISO from Releases
# 2. Flash to USB
sudo dd if=harnessOS-*.iso of=/dev/sdX bs=4M status=progress oflag=sync

# 3. Boot from USB, then:
harness-install
```

The installer guides you through disk selection, user setup, and GPU driver configuration (NVIDIA/CUDA auto-detected).

---

## AI Tools — First Run

```bash
# Claude CLI — set your API key
claude auth login

# Ollama — pull your first model
ollama pull llama3.2
ollama run llama3.2

# GitHub Copilot CLI
gh auth login
gh copilot suggest "write a docker-compose for postgres"
```

---

## Hyprland Keybindings (essentials)

| Keys | Action |
|------|--------|
| `Super + Return` | Open terminal (Kitty) |
| `Super + Space` | App launcher (Wofi) |
| `Super + C` | Claude CLI (floating terminal) |
| `Super + O` | Ollama interactive (floating terminal) |
| `Super + H/J/K/L` | Focus window (vim-style) |
| `Super + 1-9` | Switch workspace |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Print` | Screenshot selection → clipboard |

---

## Building from Source

**Any Linux host with Docker (no Arch required):**

```bash
git clone https://github.com/Codigo-Free/HarnessOS.git
cd HarnessOS
./scripts/build-docker.sh
```

**On an Arch Linux host:**

```bash
sudo ./scripts/build.sh
```

**Test in QEMU (after build):**

```bash
./scripts/test-qemu.sh
```

---

## Project Structure

```
HarnessOS/
├── archiso/          # ISO build profile (archiso)
│   ├── profiledef.sh
│   ├── packages.x86_64
│   └── airootfs/     # Files overlaid onto the live system
├── installer/        # Python TUI installer (textual)
│   └── harness_installer/
├── dotfiles/         # User configs (GNU Stow)
│   ├── hyprland/     # Hyprland + keybinds
│   ├── waybar/       # Status bar
│   ├── nvim/         # Neovim + LSP + Copilot
│   ├── kitty/        # Terminal (Tokyo Night)
│   ├── zsh/          # Shell + Starship
│   └── wofi/         # App launcher
├── scripts/          # build.sh, build-docker.sh, test-qemu.sh
└── tests/smoke/      # Post-install validation scripts
```

---

## Deploy Dotfiles Only

Already on Arch and want just the HarnessOS dotfiles?

```bash
git clone https://github.com/Codigo-Free/HarnessOS.git ~/dotfiles
cd ~/dotfiles
./scripts/deploy-dotfiles.sh
```

---

## NVIDIA / CUDA Setup

NVIDIA drivers are **not baked into the ISO** (prevents boot failures on non-NVIDIA systems). The installer detects your GPU and installs the correct driver:

- **Modern NVIDIA** (RTX 20xx/30xx/40xx): `nvidia-dkms` + CUDA
- **Legacy NVIDIA** (GTX 700/900): `nvidia-470xx-dkms`
- Always uses DKMS for compatibility with `linux-zen`

Docker is automatically configured with `nvidia-container-runtime`.

---

## BTRFS Snapshot Safety

Every `pacman -S` triggers a pre/post snapshot via `snap-pac`. To roll back after a bad update:

```bash
snapper list                    # Show available snapshots
snapper undochange 42..43       # Roll back files between snapshots
```

Or use `Timeshift` for full system rollbacks from the live ISO if the system won't boot.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add packages, propose dotfile changes, or submit PKGBUILDs.

---

## License

GPL-2.0 © [Codigo-Free](https://github.com/Codigo-Free)
