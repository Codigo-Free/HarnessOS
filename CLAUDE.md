# HarnessOS — AI Context

## Project Overview
HarnessOS is an Arch Linux-based distro for AI-powered software development.
Repository: https://github.com/Codigo-Free/HarnessOS

## Current Dev Environment (2026-06-30)
- **Host machine**: ahora booteando directo desde el SSD instalado (`/dev/sda2`, hostname `harnessOS`, BTRFS subvol `@`) — ya no es live USB.
- **Instalación en SSD**: el pacstrap parcial documentado antes (falló a ~173/300+ paquetes) dejó el sistema arrancable pero con ~70 paquetes de `archiso/packages.x86_64` faltantes (grub, tmux, jq, k9s, hyprlock, hypridle, hyprpaper, dotnet-sdk, terminus-font, etc.). Se reinstalan con `pacman -S --needed` contra la lista del repo.
- **GPU**: Intel HD 620 (iGPU, `i915`) + NVIDIA GeForce MX150 (`10de:134e`, Pascal, sin GSP) en óptimus. El sistema tenía `nvidia-open-dkms` instalado manualmente (fuera del instalador) — **no soporta GPUs sin GSP** y el kernel falla al cargar el driver. Corregido a `nvidia-dkms` (propietario), que es lo que el instalador (`installer/harness_installer/core/gpu.py`) siempre seleccionó correctamente.
- **`build-docker.sh` NO funciona** en live USB: Docker falla con `invalid argument` al montar overlayfs sobre el root que ya es overlayfs (nested overlayfs no soportado por el kernel).
- **Build en live USB**: usar `mkarchiso` directamente tras `sudo pacman -Sy archiso`. Requiere además:
  1. Activar mirrors: editar `/etc/pacman.d/mirrorlist` (CDN global a veces timeout — usar mirrors de España)
  2. Inicializar keyring: `sudo pacman-key --init && sudo pacman-key --populate archlinux`
  3. Inyectar installer manualmente: `cp -r installer/harness_installer archiso/airootfs/usr/local/lib/harness/installer/`
  4. Ejecutar: `sudo mkarchiso -v -w /tmp/harness-work -o ./out ./archiso`

## Known Issues / Gotchas (encontrados post-instalación en SSD)
- **Wallpaper ausente en sistemas instalados**: `hyprland.conf` ejecuta `swaybg -i /usr/share/harness/logo.png`, pero ese archivo solo existe en el overlay del ISO en vivo (`archiso/airootfs/usr/share/harness/logo.png`) — el instalador nunca lo copiaba al disco. **Corregido**: nueva función `deploy_branding()` en `installer/harness_installer/core/dotfiles.py`, invocada desde `progress.py` justo después de `deploy_dotfiles()`.
- **NVIDIA — nunca instalar `nvidia-open-dkms` manualmente**: GPUs pre-Turing (Maxwell/Pascal, sin GSP) no son soportadas por los módulos open-source y el kernel falla el probe (`probe with driver nvidia failed with error -1`). Usar siempre `nvidia-dkms`, como ya hace `gpu.py`.
- **`systemd-vconsole-setup.service` falla** (`setfont` exit 66) si falta el paquete `terminus-font` (usado por `FONT=ter-v18n` en `/etc/vconsole.conf`) — es uno de los paquetes que quedan fuera si pacstrap se corta a la mitad.
- **`/boot` world-readable**: con `fmask=0022,dmask=0022` en fstab, `bootctl` marca `random-seed` como agujero de seguridad. Fix: `fmask=0137,dmask=0027`.
- **USB drives no aparecen/montan solos**: el kernel y udisks2 detectan el dispositivo perfectamente (confirmado con `lsblk`/`journalctl -k` — aparece como `sdX` al instante), pero como Hyprland no trae un entorno de escritorio completo, no había ningún automounter corriendo. `udiskie` ya viene en `archiso/packages.x86_64` pero le faltaba el `exec-once` en `hyprland.conf`. Fix: agregado `exec-once = udiskie -t`.
- **Ícono de Ollama invisible en Waybar**: `harness-ollama-status` armaba el tooltip con un `printf` cuyo formato tenía un `\n` sin escapar (`'...%s\nClick to chat...'`), lo que `printf` convierte en un salto de línea real dentro del string JSON — JSON inválido, Waybar tira `Error parsing JSON` y el módulo queda en blanco. Fix: escapar como `\\n` en el formato.

## Key Technical Decisions
- **Kernel**: `linux-zen` (lower desktop latency vs mainline)
- **Driver rule**: Always use `nvidia-dkms` (NOT `nvidia`) for linux-zen compatibility
- **Filesystem**: BTRFS with subvolumes @, @home, @var, @var_log, @snapshots, @swap
- **Swap on BTRFS**: Use dedicated `@swap` subvolume with `chattr +C` (NoCoW) — never a raw swapfile on CoW BTRFS
- **Build system**: archiso via Docker (`archlinux:latest`) — en máquina normal. En live USB usar mkarchiso directo (ver sección anterior)
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
- `code` (archiso/packages.x86_64) is Arch's OSS build of VS Code — no Microsoft Marketplace access (license restricts it to official MS builds). Extensions panel shows nothing. Fix on an installed system: AUR `visual-studio-code-bin`, or point `product.json` `extensionsGallery` at Open VSX.
- `yay` (AUR helper) can't go in `archiso/packages.x86_64` (not an official repo pkg, and `makepkg` refuses to run as root during the offline chroot build). Instead it's built as the `harness` user in `harness-online-setup` (`archiso/airootfs/usr/local/bin/harness-online-setup`) on first boot with internet.

## Workflow
**Desde máquina normal (Linux, Mac, etc. con Docker):**
1. Edit files in this repo
2. `./scripts/build-docker.sh` to build ISO
3. `./scripts/test-qemu.sh` to boot test
4. Tag `vYYYY.MM.DD` → GitHub Actions builds and publishes release ISO

**Desde live USB (entorno actual):**
1. Edit files in this repo
2. Inyectar installer: `TARGET=archiso/airootfs/usr/local/lib/harness/installer; rm -rf $TARGET; mkdir -p $TARGET; cp -r installer/harness_installer $TARGET/; cp installer/requirements.txt $TARGET/`
3. `sudo pacman -Sy archiso` (solo primera vez; requiere mirrorlist activo)
4. `mkdir -p out && sudo mkarchiso -v -w /tmp/harness-work -o ./out ./archiso`
5. Flashear: `sudo dd if=out/*.iso of=/dev/sdb bs=4M status=progress oflag=sync` (reemplaza el USB actual — guardar cambios antes)

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
