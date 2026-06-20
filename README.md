# HarnessOS

**Arch Linux-based distro for AI-powered software development.**

[![Build ISO](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml)
[![Latest Release](https://img.shields.io/github/v/release/Codigo-Free/HarnessOS)](https://github.com/Codigo-Free/HarnessOS/releases)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

> Ships with Claude CLI, GitHub Copilot, Ollama, Hyprland, Docker, and a complete dev stack — ready in minutes, not hours.

---

## What ships out of the box

### AI Tools
| Tool | Command | Purpose |
|------|---------|---------|
| **Claude CLI** | `claude` | AI pair programmer (Anthropic) |
| **Ollama** | `ollama` | Run LLMs locally (llama3.2, mistral, etc.) |
| **GitHub Copilot** | `gh copilot` | Copilot CLI + Neovim plugin |

### Desktop
| Tool | Purpose |
|------|---------|
| **Hyprland** | Fast, tiling Wayland compositor |
| **Waybar** | Horizontal top bar with app icons and workspace switcher |
| **Kitty** | GPU-accelerated terminal |
| **Firefox** | Browser (`SUPER+B`) |
| **VS Code** | Editor (`SUPER+E`) |
| **Wofi** | App launcher (`SUPER+R`) |

### TUI Tools (lazy interfaces)
| Tool | Alias | Purpose |
|------|-------|---------|
| **Lazygit** | `lg` | Git TUI |
| **Lazydocker** | `lzd` | Docker TUI |
| **Yazi** | `y` | File manager (changes dir on exit) |
| **Zoxide** | `z` | Smart directory navigation |
| **Bottom** | `top` | Process monitor (replaces htop) |
| **lnav** | `logs` | Log file viewer |
| **K9s** | `k` | Kubernetes TUI |
| **Neovim** | `vim` | Editor with LSP + Copilot |

### Dev Stack
| Tool | Purpose |
|------|---------|
| **Docker + Compose** | Containerization ready |
| **Python 3** | + pip, pipx, uv, virtualenv |
| **Node.js LTS** | + npm, pnpm, TypeScript, ts-node |
| **.NET SDK** | C# development |
| **OpenJDK + Maven** | Java |
| **PHP + Composer** | Web backend |
| **kubectl** | Kubernetes CLI |
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
| `Super + R` | App launcher (Wofi) |
| `Super + B` | Firefox |
| `Super + E` | VS Code |
| `Super + C` | Claude CLI in terminal |
| `Super + O` | Ollama (llama3.2) in terminal |
| `Super + H/J/K/L` | Focus window (vim-style) |
| `Super + 1–4` | Switch workspace |
| `Super + Shift + 1–4` | Move window to workspace |
| `Super + W` | Close window |
| `Super + F` | Fullscreen |
| `Print` | Screenshot selection |

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

## Documentation

| Doc | Description |
|-----|-------------|
| [Overview](docs/01-overview.md) | What is HarnessOS, what ships, target audience |
| [Building](docs/02-building.md) | Build from source with Docker or native Arch |
| [Live Environment](docs/03-live-environment.md) | Booting, keybindings, live user, online setup |
| [Installation](docs/04-installation.md) | TUI installer walkthrough, disk layout, GPU setup |
| [AI Tools](docs/05-ai-tools.md) | Claude, Ollama, Copilot — usage and configuration |
| [Troubleshooting](docs/06-troubleshooting.md) | Common boot, login, and build errors |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add packages, propose dotfile changes, or submit PKGBUILDs.

---

## License

GPL-2.0 © [Codigo-Free](https://github.com/Codigo-Free)
