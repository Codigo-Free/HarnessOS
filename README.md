<div align="center">

# ⬡ HarnessOS

### The AI-native operating system for software developers.

AI is not an app you install on HarnessOS.
It is part of the operating system.

[![Build ISO](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Codigo-Free/HarnessOS/actions/workflows/build-iso.yml)
[![Latest Release](https://img.shields.io/github/v/release/Codigo-Free/HarnessOS)](https://github.com/Codigo-Free/HarnessOS/releases)
[![ISO](https://img.shields.io/badge/ISO-3.3%20GB-blue)](http://148.113.174.52:8899/harnessOS-2026.07.02-x86_64.iso)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](LICENSE)

**Arch Linux** · **linux-zen** · **Hyprland (Wayland)** · **Ollama** · **Claude CLI** · **Docker** · **BTRFS**

No configuration. No dotfiles. No setup.
**Just build.**

[Download](#quick-install) · [Why HarnessOS](#why-harnessos) · [Architecture](#architecture) · [Roadmap](#roadmap)

<br>

![HarnessOS Desktop](docs/screenshots/wallpaper.jpg)

</div>

---

## Why HarnessOS

You buy a new laptop. You're excited to build.

Two days later you're still at it: installing packages, copying dotfiles from your old machine, fighting the NVIDIA driver, configuring the compositor, authenticating six CLI tools, wiring your editor to an LLM.

That's not development. That's overhead.

**HarnessOS boots straight into a finished developer workstation.** Terminal, editor, containers, local AI, cloud AI — configured, themed, and talking to each other from the first minute. And because the AI lives *inside* the OS, it doesn't just answer questions. It sees your machine.

| | **HarnessOS** | Arch | EndeavourOS | Ubuntu |
|--|:---:|:---:|:---:|:---:|
| System-aware AI in the shell | **Built-in** | — | — | — |
| Local LLMs tuned to your hardware | **First boot** | Manual | Manual | Manual |
| MCP server for AI agents | **Built-in** | — | — | — |
| Claude CLI + OpenCode + Continue | **First boot** | Manual | Manual | Manual |
| Hyprland tiling Wayland desktop | **Pre-configured** | DIY | Optional | — |
| BTRFS + automatic snapshots | **Default** | Manual | Manual | — |
| GPU driver detection (zen-safe) | **Automatic** | Manual | Manual | Manual |

---

## Quick Demo

<!-- TODO: record demo — wtf diagnosing a failed command, harness ai fixing docker -->
![HarnessOS demo](docs/screenshots/demo.gif)

```
❯ systemctl statuss ollama
Unknown command verb 'statuss'
↯ exit 2 — type 'wtf' for AI diagnosis

❯ wtf
  Typo: `statuss` → `status`. The service itself is healthy —
  ollama.service has been running for 2h 14m.

    [1]  systemctl status ollama

  Run it? [1/a/n] >
```

---

## Features

### 🤖 AI-Native

- `wtf` — diagnoses your last failed command with full system context
- `ask "..."` — one-shot answers that know your kernel, services and disks
- `Ctrl+X Ctrl+A` — explains the command at your prompt before you run it
- `harness ai` — chat with an AI that sees your machine, not a generic bot
- Local models auto-tuned to your GPU/RAM on first boot — zero API cost, zero data leaves your machine

### ⚙️ Developer-Ready

- Claude CLI, OpenCode, Continue and GitHub Copilot CLI installed on first boot
- Python, Node.js, TypeScript, Java, .NET, PHP, Docker + Compose, kubectl
- Curated TUI stack: lazygit, lazydocker, yazi, k9s, lnav, bottom, fzf, zoxide
- One-command stacks: `harness install web | ml | devops | security`

### 🖥️ Desktop

- Hyprland tiling Wayland compositor, GPU-rendered, Tokyo Night theme
- Waybar with live Ollama status · Kitty terminal · Wofi launcher
- `SUPER+Return` terminal · `SUPER+A` AI · `SUPER+E` VS Code · `SUPER+B` browser

### 🛡️ Reliability

- BTRFS subvolumes with automatic pre/post-transaction snapshots (snapper + snap-pac)
- `harness update` — snapshot before, verify after; roll back in one command
- linux-zen kernel with always-correct NVIDIA driver selection (`nvidia-dkms`)
- A hidden arcade game. Somewhere.

---

## Architecture

Every AI tool on the system shares one local brain — one model routing table, one context server, one Ollama backend.

```
       harness ai · wtf · ask │ Claude Code · OpenCode · Continue
                    └──────────────┬───┬──────────────┘
                          prompts  │   │  tools (MCP)
                                   ▼   ▼
              ┌────────────────────┐   ┌────────────────────┐
              │   Model routing    │   │    harness-mcp     │
              │ ~/.config/harness/ │   │ read-only system   │
              │    config.toml     │   │   context server   │
              │ (harness-tune-ai)  │   │                    │
              └─────────┬──────────┘   └─────────┬──────────┘
                        ▼                        ▼
              ┌────────────────────┐   ┌────────────────────┐
              │       Ollama       │   │  Live system state │
              │  local LLMs sized  │   │ journal · services │
              │  to your hardware  │   │ pacman · Docker    │
              └────────────────────┘   │ GPU · shell history│
                                       └────────────────────┘
```

- **`harness-tune-ai`** detects VRAM/RAM on first boot and picks the right model tier — `qwen2.5-coder:3b` on a modest laptop, `qwen3:27b` on a big GPU. CPU-only machines get fast non-reasoning models for interactive diagnosis. Models are pre-pulled in the background.
- **`harness-mcp`** is a zero-dependency MCP server exposing journal, services, pacman, Docker and Ollama state to any AI agent. Read-only by design — agents can *see* everything, but every mutation still needs your approval.
- Change one file, and every tool follows. One brain, many hands.

---

## Quick Install

```bash
# Download & verify
wget http://148.113.174.52:8899/harnessOS-2026.07.02-x86_64.iso
wget http://148.113.174.52:8899/harnessOS-2026.07.02-x86_64.iso.sha256
sha256sum -c harnessOS-2026.07.02-x86_64.iso.sha256

# Flash to USB
sudo dd if=harnessOS-2026.07.02-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

> The ISO boots straight into the Hyprland desktop. Latest release: **v2026.07.02.1**.

```bash
harness-install   # TUI wizard: disk, user, GPU, software — ~10 minutes
```

The installer handles BTRFS partitioning, GPU drivers, dotfiles and systemd-boot. On the first boot with internet, HarnessOS finishes itself: AI CLIs, tuned local models, MCP wiring.

---

## The `harness` CLI

```bash
harness doctor                         # verify GPU, Docker, Ollama, Claude — with fix hints
harness setup                          # authenticate GitHub, Claude, pull models
harness update                         # snapshot → update → verify
harness snapshot -m "before refactor"  # manual BTRFS snapshot
harness install ml                     # add a developer profile
harness ai                             # system-aware AI chat
```

---

## Harness AI — an AI that sees your system

ChatGPT doesn't know your kernel. Copilot can't read your journal. **Harness AI runs on your machine and knows it** — kernel, failed services, containers, GPU, disks, and your last 20 commands are injected into every conversation.

```
❯ harness ai
⬡ HarnessOS AI  (qwen2.5-coder:7b)

you › why is docker failing to start?

  Your journal shows docker.service failed 3 minutes ago with a
  conflict on the rootless socket. Your user is not in the docker
  group yet — that's the root cause.

    [1]  sudo usermod -aG docker $USER && newgrp docker
    [2]  sudo systemctl restart docker

  Run which? [1/2/a/n] > a  ✓
```

- Modes for code, diagnosis, log analysis and commit messages — each routed to the best local model
- Suggested commands always require your approval
- Sessions saved locally · `SUPER+A` opens it from anywhere

---

## Developer Profiles

One command turns the base system into your specialty:

| | Profile | What you get |
|--|---------|--------------|
| 🌐 | `harness install web` | pnpm · Bun · TypeScript · Next.js · Vercel · Tailwind |
| 🧠 | `harness install ml` | CUDA · PyTorch · Jupyter · pandas · transformers · Hugging Face |
| ☁️ | `harness install devops` | Terraform · Ansible · Helm · kubectx · AWS CLI |
| 🔐 | `harness install security` | nmap · Wireshark · hashcat · John · sqlmap · gobuster |

---

## What Ships Preinstalled

**AI** — Claude CLI, OpenCode, Continue (VS Code), Copilot CLI, Ollama with hardware-tuned models, `harness-mcp`.

**Terminal** — Kitty + zsh + Starship, tmux, and a full TUI suite (`lg` lazygit, `lzd` lazydocker, `y` yazi, `k` k9s, `logs` lnav, `top` bottom). Modern replacements everywhere: eza, bat, ripgrep, fd, zoxide, fzf.

**Languages & runtimes** — Python (pip, pipx, uv), Node.js LTS (npm, pnpm, tsx), Java + Maven, .NET SDK, PHP + Composer, Docker + Compose, kubectl.

**Desktop** — Hyprland, Waybar, Wofi, Firefox, VS Code — themed and keybound out of the box.

---

## Screenshots

![harness ai](docs/screenshots/harness-ai.png)
*`harness ai` — context-aware session, first run pulls the model automatically*

![Split view](docs/screenshots/desktop-split.png)
*Terminal beside Firefox in Hyprland*

![Dual AI](docs/screenshots/harness-ai-split.jpg)
*Two concurrent AI conversations, side by side*

---

## Build From Source

```bash
git clone https://github.com/Codigo-Free/HarnessOS.git && cd HarnessOS

./scripts/build-docker.sh   # any Linux with Docker
sudo ./scripts/build.sh     # native Arch Linux
./scripts/test-qemu.sh      # boot-test the ISO
```

---

## Technical Notes

| Decision | Choice | Why |
|----------|--------|-----|
| Kernel | linux-zen | lower desktop latency |
| NVIDIA | `nvidia-dkms`, auto-detected | survives zen kernel updates |
| Filesystem | BTRFS: `@ @home @var @var_log @snapshots @swap` | zstd compression + snapshot isolation |
| Snapshots | snapper + snap-pac | every pacman transaction is reversible |
| Swap | dedicated `@swap` subvolume, NoCoW | safe swapfile on BTRFS |

Roll back anything: `snapper list && snapper undochange 42..43`

---

## Documentation

[Overview](docs/01-overview.md) · [Building](docs/02-building.md) · [Live Environment](docs/03-live-environment.md) · [Installation](docs/04-installation.md) · [AI Tools](docs/05-ai-tools.md) · [Troubleshooting](docs/06-troubleshooting.md) · [Changelog](CHANGELOG.md) · [Wiki](https://github.com/Codigo-Free/HarnessOS/wiki)

---

## Roadmap

- [x] Harness AI — system-aware chat
- [x] Local AI brain — one routing layer for every tool
- [x] Shell AI — `wtf`, `ask`, explain-before-run
- [x] MCP system server for Claude Code, OpenCode & any agent
- [x] Hardware-tuned model selection
- [ ] AI workflows — multi-step tasks from the shell
- [ ] Plugin marketplace for profiles & tools
- [ ] GUI configuration center
- [ ] Encrypted settings sync
- [ ] Multi-agent collaboration on one system context

---

## Contributing

PRs welcome — packages, profiles, dotfiles, bug fixes. Start with [CONTRIBUTING.md](CONTRIBUTING.md).

If HarnessOS saved you a weekend of setup, **star the repo** — it helps other developers find it. ⭐

---

## Support this project

If you'd like to support ongoing development, you can sponsor via [GitHub Sponsors](https://github.com/sponsors/Codigo-Free).

---

<div align="center">

GPL-2.0 © [Codigo-Free](https://github.com/Codigo-Free)

**HarnessOS — stop configuring. Start building.**

</div>
