# HarnessOS — Overview

HarnessOS is an Arch Linux-based distribution built specifically for AI-powered software development. It ships with a complete, pre-configured development environment so you can start coding with AI assistance immediately after booting.

## What ships out of the box

| Tool | Purpose |
|------|---------|
| Claude CLI (`claude`) | AI pair programmer — conversational coding assistant |
| Ollama | Local LLM runner — run models like Llama 3.2 offline |
| GitHub Copilot CLI | AI code completion via `gh copilot` |
| Hyprland | Tiling Wayland compositor — fast, GPU-accelerated |
| Firefox | Web browser with DevTools |
| VS Code (`code`) | Editor with full language support |
| Docker + Docker Compose | Container runtime, pre-configured |
| Python + pip + uv | Python stack with modern tooling |
| Node.js + npm + pnpm | JavaScript/TypeScript runtime |
| .NET SDK | C# development |
| OpenJDK + Maven | Java development |
| PHP + Composer | PHP development |
| Neovim + lazygit | Terminal editor and git TUI |
| Kitty | GPU-accelerated terminal emulator |
| Starship | Cross-shell prompt |
| zsh + autosuggestions | Shell with completions |

## Kernel

HarnessOS uses **linux-zen** — a patched kernel optimized for desktop responsiveness and lower latency, ideal for interactive development workflows.

## Filesystem

Installed systems use **BTRFS** with subvolumes:

| Subvolume | Mount | Purpose |
|-----------|-------|---------|
| `@` | `/` | Root |
| `@home` | `/home` | User data |
| `@var` | `/var` | Variable data |
| `@var_log` | `/var/log` | Logs |
| `@snapshots` | `/.snapshots` | Snapper snapshots |
| `@swap` | `/swap` | Swap (NoCoW) |

Snapper is configured for automatic timeline snapshots. Every `pacman` operation creates a pre/post snapshot via `snap-pac`.

## Target audience

- Developers who want a pre-configured Linux environment for AI-assisted coding
- Teams standardizing on a development OS
- Users who want Arch's rolling updates with a curated defaults layer
