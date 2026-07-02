# Changelog

All notable changes to HarnessOS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [2026.07.02.1] - 2026-07-02

### Added

**Local AI brain — Ollama wired into the whole system**
- `harness-tune-ai` — detects GPU VRAM / RAM on first boot and writes the optimal model tier (low/base/mid/high) to `~/.config/harness/config.toml`; chosen models are pre-pulled in the background
- `harness-mcp` — zero-dependency MCP server exposing read-only system tools (journal, service status, pacman, docker, Ollama models) to Claude Code, OpenCode and any MCP client; registered automatically on first boot
- Shell AI integration: `wtf` (diagnose the last failed command), `ask <question>` (one-shot with system context), `Ctrl+X Ctrl+A` (explain the typed command), and a hint on real failures
- `harness-ai -q/--ask` — one-shot mode for scripts and hooks; config parsing via `tomllib`
- OpenCode preconfigured with the local Ollama provider + `harness-mcp`; Continue (VS Code) preconfigured with model auto-detect, installed from Open VSX on first boot
- `harness-online-setup` now also installs OpenClaw (best effort) and runs on installed systems, not just the live ISO
- `scripts/sync-system.sh` — sync an installed system with the repo in one command
- `pacman-contrib` in the ISO (provides `checkupdates` for `harness-mcp`)

### Fixed
- Installed systems never received the npm globals (Claude Code, OpenCode, yay): the installer now deploys and enables `harness-online-setup.service`
- `wtf` diagnosed itself instead of the failed command (preexec recorded the `wtf` line)
- CPU-only machines got 6-minute diagnoses from reasoning models: doctor/logs modes now use fast models when no dedicated GPU is present

## [2026.06.24] - 2026-06-24

### Added
- Easter egg: `SUPER+SHIFT+CTRL+G` → 3 white flashes → portrait fullscreen → Galaga game
- Galaga: full pygame clone (Tokyo Night palette), 4 enemy types, swooping, waves, explosions
- kanshi: multi-monitor profile manager — 5 profiles (laptop-only, dual-right, dual-dp-right, external-only, mirror)
- wlr-randr: CLI tool for querying and setting display outputs
- kanshi auto-starts on Hyprland login

### Fixed
- Easter egg keybind: corrected Hyprland modifier order (`$mod SHIFT CTRL` vs `$mod CTRL SHIFT`)
- Easter egg script: `SDL_VIDEODRIVER=wayland` now conditional on `WAYLAND_DISPLAY` presence (works on both X11 and Wayland)

## [2026.06.23] - 2026-06-23

### Added

**harness CLI — central command center**
- `harness info` — displays hardware summary, kernel, running services, Ollama models
- `harness doctor` — verifies GPU driver, Docker, Ollama, Claude CLI, Git, Node, pnpm, Python, Docker Compose; prints fix hints for failures
- `harness setup` — post-install wizard: GitHub CLI auth, Claude CLI install, Ollama model pull
- `harness update` — safe system update with automatic BTRFS snapshot before and after
- `harness snapshot` — manual snapshot with `-m` message flag and `--list` to browse/restore
- `harness install <profile>` — installs developer profiles (web, ml, devops, security)
- `harness ai` — dispatches to `harness-ai` with forwarded arguments

**harness ai — system-aware AI chat**
- Injects live system context into every conversation: kernel, uptime, disk, memory, failed services, Docker containers, last 20 zsh commands
- Streams responses token-by-token from Ollama (llama3.2 default, configurable)
- Detects shell commands in responses, lists them numbered, requires approval before execution
- Persists conversation history to `~/.local/share/harness/ai-sessions/`
- `--explain <cmd>` flag to explain a command without executing it
- `--model <name>` flag to override the default model
- `--no-context` flag to disable system injection for privacy

**Developer profiles**
- `web` profile: Bun, extended TypeScript tools, Vercel CLI, Tailwind CSS CLI
- `ml` profile: CUDA toolkit, cuDNN, PyTorch (CUDA), Jupyter, pandas, scikit-learn, transformers, huggingface-hub
- `devops` profile: Terraform, Ansible, Helm, kubectx, kubens, AWS CLI v2
- `security` profile: nmap, Wireshark, hashcat, John the Ripper, sqlmap, gobuster, Nikto, Metasploit

**TUI installer (Python + textual)**
- 7-screen guided installer: Welcome, Disk Setup, User Setup, GPU Detection, Software Profile, Confirm, Progress
- Welcome screen shows detected CPU, RAM, GPU
- Disk screen lists available disks with size, creates BTRFS layout automatically
- BTRFS subvolumes: @, @home, @var, @var_log, @snapshots, @swap (with `chattr +C` NoCoW on @swap)
- GPU screen auto-detects NVIDIA/AMD/Intel and installs correct drivers
- NVIDIA always uses `nvidia-dkms` for linux-zen compatibility + runs `mkinitcpio -p linux-zen`
- Progress screen streams live output from pacstrap and arch-chroot steps
- Deploys dotfiles from live harness user to installed user home
- Installs systemd-boot with correct entry for linux-zen

**Waybar enhancements**
- Ollama status widget: shows active model in green, idle in amber, offline in gray
- Click Ollama widget to open `harness ai` in Kitty terminal
- Volume widget with pulsemixer integration

**Hyprland keybindings**
- `SUPER+A` → `harness ai` (system-aware AI assistant)
- `SUPER+C` → Claude CLI
- `SUPER+O` → Ollama raw chat

**GitHub Actions CI/CD**
- `build-iso.yml` — builds ISO on push to archiso/**, installer/**, or dotfiles/**; uploads artifact (7-day retention)
- `release.yml` — triggered by `v*` tags; builds ISO, uploads to VPS, creates GitHub Release with SHA256 checksum and VPS download link
- Both workflows inject installer into airootfs before mkarchiso (critical step)
- Uses `archlinux:latest` container with `--privileged` (not ubuntu runners)

**Dotfiles deployment**
- `dotfiles.py` copies live harness user configs to installed user home
- Fixes ownership via arch-chroot + chown
- Deployed configs: Hyprland, Waybar, Kitty, Wofi, .zshrc, .zprofile

### Changed
- `harness-install` launcher now uses `python3 -m harness_installer.main` (fixes module import)
- NVIDIA installer runs `mkinitcpio -p linux-zen` after patching mkinitcpio.conf

### Technical
- Build system: `./scripts/build-docker.sh` — Docker (`archlinux:latest`) on non-Arch hosts
- Kernel: linux-zen (lower desktop latency vs mainline)
- Filesystem: BTRFS with zstd compression, noatime, space_cache=v2
- Bootloader: systemd-boot
- Network manager: NetworkManager + nmtui
- Shell: zsh + Starship prompt + zoxide + eza + bat

---

## [2026.06.21] - 2026-06-21

### Added
- Initial archiso profile with linux-zen kernel
- Hyprland + Waybar (horizontal) + Kitty + Wofi — Tokyo Night theme
- Wallpaper with HarnessOS logo (swaybg)
- Full AI dev stack: Claude CLI, Ollama, GitHub Copilot
- Languages: Python 3, Node.js LTS, .NET SDK, OpenJDK + Maven, PHP + Composer
- TUI tools: lazygit, lazydocker, yazi, zoxide, bottom, lnav, k9s
- Shell aliases: ls→eza, cat→bat, vim→nvim, d→docker, lg→lazygit, y→yazi
- Docker + Compose + nvidia-container-runtime
- BTRFS filesystem with snapper timeline snapshots
- `harness-detect-gpu` — GPU detection library (conditionally sets NVIDIA Wayland env vars)
- `harness-power` — power menu (shutdown / reboot / suspend)
- `harness-welcome` — first-boot welcome message
- `harness-online-setup.service` — installs npm globals on first internet connection
- GNU Stow dotfile management structure
- UEFI-only boot (GRUB-less, systemd-boot)

[2026.06.24]: https://github.com/Codigo-Free/HarnessOS/releases/tag/v2026.06.24
[2026.06.23]: https://github.com/Codigo-Free/HarnessOS/releases/tag/v2026.06.23
[2026.06.21]: https://github.com/Codigo-Free/HarnessOS/releases/tag/v2026.06.21
