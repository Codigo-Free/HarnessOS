# Building HarnessOS

## Requirements

| Method | Requirements |
|--------|-------------|
| Docker (recommended) | Docker installed, any Linux distro |
| Native | Arch Linux host |

The Docker method works on any Linux system (Ubuntu, Mint, Fedora, etc.) and is the recommended approach for development.

## Quick build (Docker)

```bash
git clone https://github.com/Codigo-Free/HarnessOS.git
cd HarnessOS
./scripts/build-docker.sh
```

The ISO is output to `out/harnessOS-YYYY.MM.DD-x86_64.iso`. Build time is approximately 20–40 minutes depending on internet speed and CPU (the SquashFS XZ compression step is the slowest part).

## What the build does

1. Pulls `archlinux:latest` Docker image
2. Installs `archiso` inside the container
3. Copies the installer (`installer/`) into the airootfs
4. Runs `mkarchiso` to build the ISO:
   - Installs all packages from `packages.x86_64` via pacstrap
   - Runs `customize_airootfs.sh` inside the chroot (enables services, creates users, generates wallpaper, rebuilds initramfs)
   - Compresses the filesystem into a SquashFS image
   - Wraps it in an ISO 9660 image with systemd-boot for UEFI

## Native build (Arch Linux only)

```bash
./scripts/build.sh
```

Requires `archiso` installed on the host: `sudo pacman -S archiso`

## Testing in QEMU

```bash
# Install QEMU and UEFI firmware first (Debian/Ubuntu/Mint)
sudo apt install qemu-system-x86 ovmf -y

# Boot the latest ISO
./scripts/test-qemu.sh
```

## CI/CD

Every push to `main` that touches `archiso/**` or `installer/**` triggers a GitHub Actions build using `archlinux:latest` container. ISOs are uploaded as build artifacts.

Tags matching `vYYYY.MM.DD` trigger a release build that attaches the ISO to a GitHub Release.

## Key technical decisions

**No `autodetect` mkinitcpio hook** — `autodetect` scans running hardware to prune modules. It fails in Docker/CI containers (no real hardware). We remove it and instead explicitly list required modules (`usb_storage`, `squashfs`) in `mkinitcpio.conf.d/archiso.conf`.

**`mkinitcpio-archiso` package** — archiso v73+ moved the live-boot mkinitcpio hooks (`archiso`, `archiso_loop_mnt`, etc.) into a separate package `mkinitcpio-archiso`. This package must be in `packages.x86_64` and the initramfs must be rebuilt in `customize_airootfs.sh` after airootfs files are applied.

**`nvidia-dkms` not `nvidia`** — The `nvidia` package only builds for the mainline kernel. `nvidia-dkms` builds against any kernel including linux-zen. NVIDIA drivers are installed by the TUI installer at install time, not in the live ISO.

## Directory layout

```
archiso/
├── profiledef.sh              # ISO identity, build mode, bootmodes
├── packages.x86_64            # Full package list
├── pacman.conf                # pacman config for build (no [community], merged into [extra])
└── airootfs/                  # Overlaid onto live system root
    ├── etc/
    │   ├── mkinitcpio.conf.d/archiso.conf   # Live initramfs HOOKS
    │   ├── mkinitcpio.d/linux-zen.preset    # Preset pointing to archiso.conf
    │   └── systemd/system/
    │       ├── harness-firstboot.service
    │       ├── harness-online-setup.service
    │       └── getty@tty1.service.d/autologin.conf
    ├── home/harness/
    │   ├── .zprofile                        # Auto-launches Hyprland on tty1
    │   └── .config/
    │       ├── hypr/hyprland.conf           # Hyprland config + keybindings
    │       ├── hypr/hyprpaper.conf          # Wallpaper config
    │       └── waybar/                      # Sidebar config + CSS
    ├── root/
    │   └── customize_airootfs.sh            # Post-build chroot hook
    └── usr/local/bin/
        ├── harness-install                  # TUI installer launcher
        ├── harness-detect-gpu               # GPU detection
        ├── harness-welcome                  # Welcome screen
        └── harness-online-setup             # First-boot npm installs
```
