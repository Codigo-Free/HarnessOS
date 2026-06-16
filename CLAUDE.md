# HarnessOS — AI Context

## Project Overview
HarnessOS is an Arch Linux-based distro for AI-powered software development.
Repository: https://github.com/Codigo-Free/HarnessOS

## Key Technical Decisions
- **Kernel**: `linux-zen` (lower desktop latency vs mainline)
- **Driver rule**: Always use `nvidia-dkms` (NOT `nvidia`) for linux-zen compatibility
- **Filesystem**: BTRFS with subvolumes @, @home, @var, @var_log, @snapshots, @swap
- **Swap on BTRFS**: Use dedicated `@swap` subvolume with `chattr +C` (NoCoW) — never a raw swapfile on CoW BTRFS
- **Build system**: archiso via Docker (`archlinux:latest`) — this host is Linux Mint, not Arch
- **CI**: GitHub Actions with `container: image: archlinux:latest` — NOT ubuntu runners for archiso builds
- **Dotfiles**: GNU Stow, directory mirrors $HOME structure
- **TUI Installer**: Python + `textual` library
- **NVIDIA Wayland**: `WLR_NO_HARDWARE_CURSORS=1`, `GBM_BACKEND=nvidia-drm` — conditionally set by `harness-detect-gpu`, NOT hardcoded for all users

## Directory Layout
- `archiso/` — ISO build profile
- `archiso/airootfs/` — Files overlaid onto live system root
- `archiso/airootfs/root/customize_airootfs.sh` — Post-build chroot hook (CRITICAL)
- `installer/harness_installer/` — Python TUI installer
- `dotfiles/` — All user configs (stow packages)
- `scripts/build-docker.sh` — Primary build method on this machine
- `scripts/lib/detect.sh` — GPU detection library (sourced by other scripts)

## Package Notes
- Claude CLI: `npm install -g @anthropic-ai/claude-code`
- pnpm: `npm install -g pnpm`
- TypeScript: `npm install -g typescript ts-node tsx`
- Ollama: in official Arch repo as `ollama`
- Models NOT pre-baked in ISO (too large) — first run: `ollama pull llama3.2`

## Workflow
1. Edit files in this repo
2. `./scripts/build-docker.sh` to build ISO
3. `./scripts/test-qemu.sh` to boot test
4. Tag `vYYYY.MM.DD` → GitHub Actions builds and publishes release ISO
