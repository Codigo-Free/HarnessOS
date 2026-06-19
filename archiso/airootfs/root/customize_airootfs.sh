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
# WALLPAPER — generate dark gradient PNG for HarnessOS
# ---------------------------------------------------------------------------
mkdir -p /usr/share/harness
python3 - << 'PYEOF'
import struct, zlib

def png_chunk(name, data):
    raw = name + data
    return struct.pack('>I', len(data)) + raw + struct.pack('>I', zlib.crc32(raw) & 0xffffffff)

W, H = 1920, 1080

# Gradient: dark purple (top) → deep teal (bottom)
# Clearly distinct from Hyprland background_color 0x0a0e1a=(10,14,26)
rows = []
for y in range(H):
    t = y / (H - 1)   # 0=top, 1=bottom

    # Top: dark purple (30,15,55) → Bottom: dark teal (8,45,65)
    r = int(30  - t * 22)
    g = int(15  + t * 30)
    b = int(55  + t * 10)

    # Horizontal accent band at 55% height (subtle lighter stripe)
    if 0.53 < t < 0.57:
        fade = 1.0 - abs(t - 0.55) / 0.02
        r = min(255, r + int(fade * 15))
        g = min(255, g + int(fade * 25))
        b = min(255, b + int(fade * 30))

    rows.append(b'\x00' + bytes([r, g, b] * W))

ihdr = struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)
idat = zlib.compress(b''.join(rows), 6)
png  = (b'\x89PNG\r\n\x1a\n'
        + png_chunk(b'IHDR', ihdr)
        + png_chunk(b'IDAT', idat)
        + png_chunk(b'IEND', b''))

with open('/usr/share/harness/wallpaper.png', 'wb') as f:
    f.write(png)
print('Wallpaper generated.')
PYEOF

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
