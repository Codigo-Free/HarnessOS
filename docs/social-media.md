# HarnessOS — Social Media Posts

Ready-to-use posts for each platform. Copy, add screenshots, and post.

---

## Twitter / X

**Launch post:**

```
Just shipped HarnessOS v2026.06.23

An Arch-based distro built for AI-powered dev. Boot → coding in minutes, not hours.

What ships on first boot:
• Claude CLI (authenticated)
• Ollama + llama3.2 (local LLM)
• harness ai — AI chat that sees your running services
• Hyprland, lazygit, k9s, Docker, BTRFS snapshots

Download: http://148.113.174.52:8899/harnessOS-2026.06.23-x86_64.iso

github.com/Codigo-Free/HarnessOS
```

**harness ai thread:**

```
The interesting part of HarnessOS isn't the distro — it's `harness ai`

It's a terminal AI chat that injects your real system state before every message:
• Kernel + uptime
• Disk and memory usage
• Failed systemd services
• Running Docker containers
• Your last 20 shell commands

So "why is Docker failing?" actually gets a useful answer.

[attach harness-ai screenshot]
```

**Quick feature highlight:**

```
HarnessOS `harness` CLI does what you'd normally spend a weekend on:

harness setup    → auth GitHub + Claude + pull Ollama model
harness doctor   → check every tool, show fix hints
harness update   → BTRFS snapshot before touching anything
harness install ml  → full CUDA/PyTorch/Jupyter stack

github.com/Codigo-Free/HarnessOS
```

---

## LinkedIn

**Launch post:**

```
Releasing HarnessOS — an Arch Linux distribution built specifically for AI-assisted software development.

The problem it solves: every new machine means hours of setup — configuring a tiling compositor, installing CLI tools, authenticating dev accounts, tuning NVIDIA drivers. Most developers do this repeatedly throughout their careers.

HarnessOS ships all of it pre-configured:
- Claude CLI and GitHub Copilot, ready on first boot
- Ollama with llama3.2 for local AI (no API key needed)
- harness ai: a terminal AI assistant that reads your actual system state — failed services, running containers, recent commands — before responding
- Hyprland (Wayland tiling compositor) with Tokyo Night theme
- lazygit, lazydocker, k9s, yazi, and 40+ developer tools
- BTRFS filesystem with automatic snapshots on every system update
- One command to add an entire tool stack: harness install ml installs CUDA, PyTorch, Jupyter, and related ML tooling

The distro is built from source with archiso, uses the linux-zen kernel for lower desktop latency, and includes a TUI installer that handles GPU detection, BTRFS partitioning, and dotfile deployment automatically.

Built on Arch Linux — so the package ecosystem is fully available via pacman and the AUR.

ISO download: http://148.113.174.52:8899/harnessOS-2026.06.23-x86_64.iso
GitHub: https://github.com/Codigo-Free/HarnessOS

Open source, GPL-2.0.
```

---

## Reddit — r/unixporn

**Title:** `[Hyprland] HarnessOS — Arch distro for AI dev, ships with Claude + Ollama pre-configured`

**Post body:**

```
This is HarnessOS, an Arch-based distribution built for AI-powered software development.

**What ships out of the box:**
- Hyprland + Waybar (horizontal, Tokyo Night) with an Ollama status widget
- Claude CLI + GitHub Copilot + Ollama (llama3.2)
- `harness ai` — terminal AI chat that injects your real system state (failed services, docker containers, recent commands) before every message
- lazygit, lazydocker, k9s, yazi, bottom, lnav
- Docker + nvidia-container-runtime, auto-configured
- BTRFS + snapper — snapshot on every pacman transaction
- linux-zen kernel

**The harness CLI:**
Everything through one command: harness info, doctor, setup, update, snapshot, install <profile>, ai

**Dotfiles:** Hyprland, Waybar, Kitty, Neovim, Zsh — all in the repo, managed with GNU Stow.

**Download:** http://148.113.174.52:8899/harnessOS-2026.06.23-x86_64.iso
**GitHub:** https://github.com/Codigo-Free/HarnessOS

[attach desktop.png]
```

---

## Reddit — r/archlinux

**Title:** `HarnessOS — Arch-based distro with harness ai (system-aware local AI chat), Hyprland, and a TUI installer`

**Post body:**

```
Released HarnessOS, an Arch-based distro targeting developers who want a complete AI dev environment without the manual setup.

**Technical choices:**
- linux-zen kernel (lower desktop latency)
- BTRFS with @, @home, @var, @var_log, @snapshots, @swap subvolumes (chattr +C on @swap)
- nvidia-dkms (not nvidia) — required for linux-zen
- systemd-boot
- TUI installer written in Python with textual
- GNU Stow dotfile management

**What's different:**
`harness ai` is a local AI chat (Ollama backend) that builds a system context prompt from `uname`, `df`, `free`, `systemctl list-units --failed`, `docker ps`, and the last 20 lines of zsh history before sending your message. Extracted shell commands are presented numbered and require approval before execution.

**Build:**
Any Linux with Docker: `./scripts/build-docker.sh`
GitHub Actions: archlinux:latest container with --privileged

**GitHub:** https://github.com/Codigo-Free/HarnessOS
```

---

## Hacker News

**Title:** `HarnessOS – Arch Linux distro with a system-aware AI assistant built in`

**Comment body for "Show HN":**

```
HarnessOS is an Arch Linux-based distribution I've been building for AI-assisted software development.

The interesting technical piece is `harness ai` — a terminal AI chat that constructs a system context prompt from live data (kernel version, disk/memory state, failed systemd units, running Docker containers, last 20 shell commands) and injects it before each conversation turn. Responses with shell commands are extracted via regex, listed with numbers, and require explicit approval before execution. Backend is Ollama (local LLM, default llama3.2) via its streaming HTTP API.

The rest of it is Hyprland + Waybar (with an Ollama status widget), a 7-screen TUI installer written with Python/textual that handles BTRFS partitioning + subvolume setup + GPU detection, and a `harness` CLI dispatcher for common operations (snapshot, update, install dev profiles, doctor).

Built with archiso in Docker (host is Linux Mint), deployed to a VPS, CI via GitHub Actions with an archlinux:latest container.

GitHub: https://github.com/Codigo-Free/HarnessOS
ISO: http://148.113.174.52:8899/harnessOS-2026.06.23-x86_64.iso
```
