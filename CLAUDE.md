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

## CI/CD — GitHub Actions

Two workflows in `.github/workflows/`:

| Workflow | Trigger | What it does |
|---|---|---|
| `build-iso.yml` | push to `main` (archiso/**, installer/**, dotfiles/**) | Build ISO, upload as artifact (7-day retention) |
| `release.yml` | push tag `v*` | Build ISO → upload to VPS → create GitHub Release |

**CRITICAL — installer injection**: Both workflows run this before `mkarchiso`:
```bash
TARGET="archiso/airootfs/usr/local/lib/harness/installer"
cp -r installer/harness_installer "$TARGET/"
cp    installer/requirements.txt   "$TARGET/"
```
The `airootfs/usr/local/lib/harness/installer/` path is gitignored — it's generated at build time.

**GitHub Secrets required** (set at https://github.com/Codigo-Free/HarnessOS/settings/secrets/actions):

| Secret | Value |
|---|---|
| `VPS_SSH_KEY` | Private key of `github-actions-harnessOS-ci` ED25519 keypair |
| `VPS_HOST` | `148.113.174.52` |
| `VPS_USER` | `debian` |

The CI public key is already in `/home/debian/.ssh/authorized_keys` on the VPS.
The private key to paste into `VPS_SSH_KEY` is in `/tmp/harness_ci_key` on the dev machine (do not commit).

## ISO Distribution
- ISO hosted on VPS: `http://148.113.174.52:8899/harnessOS-YYYY.MM.DD-x86_64.iso`
- Served by `harnessOS-downloads` nginx container (docker-compose at `/home/debian/harnessOS-downloads/`)
- GitHub Releases has 2 GB limit — ISO (3 GB) goes to VPS; only `.sha256` checksum goes to GitHub Release asset
