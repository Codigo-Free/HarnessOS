#!/usr/bin/env bash
# HarnessOS — Post-build customization hook
# Runs inside the chroot during ISO build (NO internet access here).
# Internet-dependent setup (npm globals, gh extensions) goes in harness-online-setup.
set -euo pipefail

echo ">>> HarnessOS: customize_airootfs.sh starting..."

# ---------------------------------------------------------------------------
# LOCALE
# ---------------------------------------------------------------------------
sed -i 's/#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# ---------------------------------------------------------------------------
# PACMAN KEYRING — must be initialized in the live env itself, not just on
# the build host. Without this the live ISO boots with no /etc/pacman.d/gnupg
# at all, and any pacman/pacstrap operation from the live session (including
# harness-install) fails with "keyring is not writable" for every package.
# Offline-safe: reads from the already-installed archlinux-keyring package.
# ---------------------------------------------------------------------------
pacman-key --init
pacman-key --populate archlinux

# ---------------------------------------------------------------------------
# SHELL — set zsh as default for root in live env
# ---------------------------------------------------------------------------
chsh -s /bin/zsh root

# ---------------------------------------------------------------------------
# ROOT PASSWORD — unlock for live environment
# ---------------------------------------------------------------------------
passwd -d root

# ---------------------------------------------------------------------------
# LIVE USER — create 'harness' user for Hyprland (cannot run as root)
# ---------------------------------------------------------------------------
useradd -m -G wheel,docker,audio,video,input,storage -s /bin/zsh harness
passwd -d harness
echo "harness ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/harness
chmod 440 /etc/sudoers.d/harness
chown -R harness:harness /home/harness

# ---------------------------------------------------------------------------
# SERVICES
# ---------------------------------------------------------------------------
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable docker.service
systemctl enable ollama.service
systemctl enable udisks2.service
systemctl enable harness-firstboot.service
systemctl enable harness-online-setup.service
systemctl enable harness-mirrors.service

# Disable conflicting network services
systemctl disable dhcpcd.service 2>/dev/null || true

# ---------------------------------------------------------------------------
# JOURNALD — reduce console noise
# ---------------------------------------------------------------------------
sed -i 's/#SystemMaxUse=/SystemMaxUse=200M/' /etc/systemd/journald.conf

# ---------------------------------------------------------------------------
# DOCKER GROUP
# ---------------------------------------------------------------------------
groupadd -f docker

# ---------------------------------------------------------------------------
# SUDOERS PERMISSIONS
# ---------------------------------------------------------------------------
chmod 440 /etc/sudoers.d/wheel

# ---------------------------------------------------------------------------
# INITRAMFS — regenerate with archiso preset AFTER our config files are in place
# The linux-zen package builds the initramfs during pacstrap using its default
# preset. We override the preset here and rebuild so the archiso hook is included.
# ---------------------------------------------------------------------------
mkinitcpio -p linux-zen

# ---------------------------------------------------------------------------
# WALLPAPER — logo.png is baked in via airootfs overlay at /usr/share/harness/logo.png
# swaybg uses it directly as wallpaper (no generation needed)
# ---------------------------------------------------------------------------
echo "Wallpaper: /usr/share/harness/logo.png baked in via airootfs."

# ---------------------------------------------------------------------------
# ASCII LOGO
# ---------------------------------------------------------------------------
mkdir -p /usr/local/share/harness
cat > /usr/local/share/harness/ascii-logo.txt << 'LOGO'

  ██╗  ██╗ █████╗ ██████╗ ███╗   ██╗███████╗███████╗███████╗
  ██║  ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝██╔════╝
  ███████║███████║██████╔╝██╔██╗ ██║█████╗  ███████╗███████╗
  ██╔══██║██╔══██║██╔══██╗██║╚██╗██║██╔══╝  ╚════██║╚════██║
  ██║  ██║██║  ██║██║  ██║██║ ╚████║███████╗███████║███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝
                  AI-Powered Development OS
                  github.com/Codigo-Free/HarnessOS

LOGO

# ---------------------------------------------------------------------------
# FONT CACHE — rebuild so waybar/GTK can find all installed fonts
# ---------------------------------------------------------------------------
fc-cache -fv &>/dev/null || true

echo ">>> HarnessOS: customize_airootfs.sh done."
