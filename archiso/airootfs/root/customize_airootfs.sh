#!/usr/bin/env bash
# HarnessOS — Post-build customization hook
# Runs inside the chroot during ISO build (NO internet access here).
# Internet-dependent setup (npm globals, gh extensions) goes in harness-online-setup.
set -euo pipefail

echo ">>> HarnessOS: customize_airootfs.sh starting..."

# ---------------------------------------------------------------------------
# LOCALE
# ---------------------------------------------------------------------------
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# ---------------------------------------------------------------------------
# SHELL — set zsh as default for root in live env
# ---------------------------------------------------------------------------
chsh -s /bin/zsh root

# ---------------------------------------------------------------------------
# ROOT PASSWORD — unlock for live environment (no password needed on live USB)
# ---------------------------------------------------------------------------
passwd -d root

# ---------------------------------------------------------------------------
# SERVICES
# ---------------------------------------------------------------------------
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable docker.service
systemctl enable ollama.service
systemctl enable harness-firstboot.service
systemctl enable harness-online-setup.service

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

echo ">>> HarnessOS: customize_airootfs.sh done."
