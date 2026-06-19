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
import struct, zlib, math

def png_chunk(name, data):
    raw = name + data
    return struct.pack('>I', len(data)) + raw + struct.pack('>I', zlib.crc32(raw) & 0xffffffff)

W, H = 1920, 1080

# Base gradient: dark navy bottom, slightly lighter navy top
# with a subtle cyan glow in the center-bottom area
rows = []
for y in range(H):
    t = y / (H - 1)          # 0 = top, 1 = bottom
    row = bytearray(b'\x00') # filter byte

    for x in range(W):
        fx = x / (W - 1)     # 0 = left, 1 = right

        # Background gradient: top-left slightly lighter, bottom-right darker
        base_r = int(8  + (1 - t) * 10 + (1 - fx) * 4)
        base_g = int(12 + (1 - t) * 8  + (1 - fx) * 4)
        base_b = int(24 + (1 - t) * 12 + (1 - fx) * 6)

        # Subtle radial cyan glow from bottom-center
        dx = fx - 0.5
        dy = t - 1.0
        dist = math.sqrt(dx*dx + dy*dy * 0.3)
        glow = max(0.0, 1.0 - dist * 2.2) ** 2

        # Subtle grid lines (2px every 80px) in muted teal
        gx = x % 80
        gy = y % 80
        grid = 0.04 if (gx < 2 or gy < 2) else 0.0

        r = min(255, int(base_r + glow * 14 + grid * 30))
        g = min(255, int(base_g + glow * 30 + grid * 60))
        b = min(255, int(base_b + glow * 50 + grid * 80))

        row += bytes([r, g, b])

    rows.append(bytes(row))

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
