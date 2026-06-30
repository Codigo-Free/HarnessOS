#!/usr/bin/env bash
# HarnessOS CLI Installer — fallback when TUI installer fails
# Usage: curl -fsSL https://raw.githubusercontent.com/Codigo-Free/HarnessOS/main/scripts/install-cli.sh | sudo bash
set -euo pipefail

LOG="/tmp/harness-install.log"
exec > >(tee -a "$LOG") 2>&1

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RST='\033[0m'; BOLD='\033[1m'

die()  { echo -e "${RED}✗ $*${RST}" >&2; exit 1; }
ok()   { echo -e "${GREEN}✓ $*${RST}"; }
info() { echo -e "${CYAN}▶ $*${RST}"; }
warn() { echo -e "${YELLOW}⚠ $*${RST}"; }

echo -e "${CYAN}${BOLD}"
echo "  ██╗  ██╗ █████╗ ██████╗ ███╗   ██╗███████╗███████╗███████╗"
echo "  ██║  ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝██╔════╝"
echo "  ███████║███████║██████╔╝██╔██╗ ██║█████╗  ███████╗███████╗"
echo "  ██╔══██║██╔══██║██╔══██╗██║╚██╗██║██╔══╝  ╚════██║╚════██║"
echo "  ██║  ██║██║  ██║██║  ██║██║ ╚████║███████╗███████║███████║"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝"
echo -e "${RST}"
echo -e "  ${BOLD}HarnessOS CLI Installer${RST}  —  Log: $LOG"
echo ""

[[ $EUID -ne 0 ]] && die "Run as root: sudo bash install-cli.sh"
ping -c1 -W3 archlinux.org &>/dev/null || die "No internet. Connect with: nmtui"

# ── Preflight helpers ─────────────────────────────────────────────────────────

ensure_mirrors() {
    info "Checking pacman mirrors ..."
    if ! grep -q "^Server" /etc/pacman.d/mirrorlist 2>/dev/null; then
        warn "No mirrors found — writing defaults"
        cat > /etc/pacman.d/mirrorlist <<'EOF'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
EOF
    fi
    pacman -Syy --noconfirm || die "pacman -Syy failed — check network and mirrors"
    ok "Mirrors ready"
}

init_keyring() {
    info "Initializing pacman keyring ..."
    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux
    ok "Keyring initialized"
}

wait_for_device() {
    local dev=$1
    for i in {1..10}; do
        [[ -b "$dev" ]] && return 0
        sleep 1
    done
    die "Device not ready after 10s: $dev"
}

# ── Collect install parameters ────────────────────────────────────────────────

echo "Available disks:"
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop\|sr\|zram"
echo ""
read -rp "Target disk (e.g. /dev/sda): " DISK
[[ -b "$DISK" ]] || die "Not a block device: $DISK"
warn "ALL DATA ON $DISK WILL BE ERASED. Are you sure? [yes/no]"
read -rp "> " CONFIRM
[[ "$CONFIRM" == "yes" ]] || die "Aborted."

read -rp "Hostname [harnessOS]: "  HOSTNAME;  HOSTNAME="${HOSTNAME:-harnessOS}"
read -rp "Username [harness]: "    USERNAME;  USERNAME="${USERNAME:-harness}"
read -rsp "Password: "             PASSWORD;  echo
read -rsp "Confirm password: "     PASSWORD2; echo
[[ "$PASSWORD" == "$PASSWORD2" ]] || die "Passwords do not match."
read -rp "Timezone [America/Bogota]: " TIMEZONE; TIMEZONE="${TIMEZONE:-America/Bogota}"
read -rp "Locale [en_US.UTF-8]: " LOCALE; LOCALE="${LOCALE:-en_US.UTF-8}"
read -rp "Swap size in GB [4]: "  SWAP_GB; SWAP_GB="${SWAP_GB:-4}"

# NVIDIA detection
GPU_INFO=$(lspci | grep -i "vga\|3d\|display" || true)
INSTALL_NVIDIA=false
if echo "$GPU_INFO" | grep -qi nvidia; then
    warn "NVIDIA GPU detected: $GPU_INFO"
    read -rp "Install NVIDIA drivers? [Y/n]: " _NV
    [[ "${_NV:-y}" =~ ^[Yy] ]] && INSTALL_NVIDIA=true
fi

echo ""
info "Configuration:"
echo "  Disk     : $DISK"
echo "  Hostname : $HOSTNAME"
echo "  User     : $USERNAME"
echo "  Timezone : $TIMEZONE"
echo "  NVIDIA   : $INSTALL_NVIDIA"
echo ""
read -rp "Proceed? [yes/no]: " GO
[[ "$GO" == "yes" ]] || die "Aborted."

MP="/mnt"

# ── Preflight ─────────────────────────────────────────────────────────────────
info "Step 0/13 — Preflight checks ..."
ensure_mirrors
init_keyring

# ── 1. Partition ──────────────────────────────────────────────────────────────
info "Step 1/13 — Partitioning $DISK ..."
wipefs -af "$DISK"
sgdisk "$DISK" \
    -n 1:0:+512M -t 1:ef00 -c 1:EFI \
    -n 2:0:0     -t 2:8300 -c 2:ROOT
partprobe "$DISK"

if [[ "$DISK" == *nvme* ]]; then
    EFI="${DISK}p1"; ROOT="${DISK}p2"
else
    EFI="${DISK}1";  ROOT="${DISK}2"
fi

wait_for_device "$EFI"
wait_for_device "$ROOT"
ok "Partitioned: EFI=$EFI  ROOT=$ROOT"

# ── 2. Format ─────────────────────────────────────────────────────────────────
info "Step 2/13 — Formatting ..."
mkfs.fat -F32 -n EFI "$EFI"
mkfs.btrfs -f -L HarnessOS "$ROOT"
ok "Formatted"

# ── 3. BTRFS subvolumes ───────────────────────────────────────────────────────
info "Step 3/13 — Creating BTRFS subvolumes ..."
mount -t btrfs "$ROOT" "$MP" || die "Failed to mount BTRFS root"
for sv in @ @home @var @var_log @snapshots @swap; do
    btrfs subvolume create "$MP/$sv"
done
umount "$MP"

# Validate all subvolumes were created
mount -t btrfs "$ROOT" "$MP"
for sv in @ @home @var @var_log @snapshots @swap; do
    btrfs subvolume list "$MP" | grep -q " $sv$" || die "Missing subvolume: $sv"
done
umount "$MP"

OPTS="noatime,compress=zstd:1,space_cache=v2"
mount -o "${OPTS},subvol=@" -t btrfs "$ROOT" "$MP" || die "Failed to mount @ subvolume"
mkdir -p "$MP"/{home,var,var/log,.snapshots,swap,boot}
mount -o "${OPTS},subvol=@home"      -t btrfs "$ROOT" "$MP/home"
mount -o "${OPTS},subvol=@var"       -t btrfs "$ROOT" "$MP/var"
mount -o "${OPTS},subvol=@var_log"   -t btrfs "$ROOT" "$MP/var/log"
mount -o "${OPTS},subvol=@snapshots" -t btrfs "$ROOT" "$MP/.snapshots"
mount -o "${OPTS},subvol=@swap"      -t btrfs "$ROOT" "$MP/swap"
chattr +C "$MP/swap"
mount "$EFI" "$MP/boot"
ok "Subvolumes mounted"

# ── 4. Swapfile ───────────────────────────────────────────────────────────────
info "Step 4/13 — Creating ${SWAP_GB}GB swapfile ..."
btrfs filesystem mkswapfile --size="${SWAP_GB}g" "$MP/swap/swapfile"
swapon "$MP/swap/swapfile"
ok "Swapfile active"

# ── 5. pacstrap ───────────────────────────────────────────────────────────────
info "Step 5/13 — Installing base system (this takes ~10 min) ..."
pacstrap -K "$MP" \
    base base-devel linux-zen linux-zen-headers linux-firmware \
    mkinitcpio efibootmgr networkmanager bluez \
    btrfs-progs snapper snap-pac sudo nano vim neovim git curl wget \
    zsh zsh-autosuggestions zsh-syntax-highlighting starship \
    docker docker-compose docker-buildx \
    python python-pip python-pipx nodejs npm jdk-openjdk \
    ollama github-cli \
    hyprland waybar kitty wofi swaync swaybg \
    xdg-desktop-portal-hyprland polkit-kde-agent \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    ttf-jetbrains-mono-nerd otf-font-awesome \
    stow fzf ripgrep fd bat eza zoxide lazygit yazi bottom lnav \
    kanshi wlr-randr python-textual python-pygame imv || {
        warn "pacstrap failed — dumping mirror and pacman state"
        cat /etc/pacman.d/mirrorlist
        pacman -Syy --noconfirm
        die "pacstrap failed — see log: $LOG"
    }
ok "Base system installed"

# ── 6. fstab ─────────────────────────────────────────────────────────────────
info "Step 6/13 — Generating fstab ..."
genfstab -U "$MP" >> "$MP/etc/fstab"
ok "fstab generated"

# ── 7. System config ──────────────────────────────────────────────────────────
info "Step 7/13 — Configuring system ..."
echo "$HOSTNAME" > "$MP/etc/hostname"
cat > "$MP/etc/hosts" <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

arch-chroot "$MP" ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
arch-chroot "$MP" hwclock --systohc

# Locale
sed -i "s/^#${LOCALE}/${LOCALE}/" "$MP/etc/locale.gen"
arch-chroot "$MP" locale-gen
echo "LANG=${LOCALE%% *}" > "$MP/etc/locale.conf"
ok "System configured"

# ── 8. User ───────────────────────────────────────────────────────────────────
info "Step 8/13 — Creating user $USERNAME ..."
arch-chroot "$MP" useradd -m -G wheel,docker,audio,video,input -s /bin/zsh "$USERNAME"
echo "${USERNAME}:${PASSWORD}" | arch-chroot "$MP" chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > "$MP/etc/sudoers.d/wheel"
chmod 440 "$MP/etc/sudoers.d/wheel"
ok "User $USERNAME created"

# ── 9. GPU drivers ────────────────────────────────────────────────────────────
info "Step 9/13 — GPU drivers ..."
if [[ "$INSTALL_NVIDIA" == "true" ]]; then
    arch-chroot "$MP" pacman -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings \
        libva-nvidia-driver
    sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
        "$MP/etc/mkinitcpio.conf"
    arch-chroot "$MP" mkinitcpio -p linux-zen || die "mkinitcpio failed — check $LOG"
    [[ -f "$MP/boot/initramfs-linux-zen.img" ]] || die "initramfs-linux-zen.img not generated"
    ok "NVIDIA drivers installed"
else
    ok "No proprietary GPU driver needed"
fi

# ── 10. Services ─────────────────────────────────────────────────────────────
info "Step 10/13 — Enabling services ..."
for svc in NetworkManager bluetooth docker ollama snapper-timeline.timer snapper-cleanup.timer; do
    arch-chroot "$MP" systemctl enable "$svc" 2>/dev/null || warn "Could not enable $svc"
done
ok "Services enabled"

# ── 11. Bootloader ───────────────────────────────────────────────────────────
info "Step 11/13 — Installing systemd-boot ..."
arch-chroot "$MP" bootctl --path=/boot install
ROOT_UUID=$(blkid -s UUID -o value "$ROOT")

# Ensure loader directories exist even if bootctl had partial failure
mkdir -p "$MP/boot/loader/entries"

cat > "$MP/boot/loader/entries/harnessOS.conf" <<EOF
title   HarnessOS (linux-zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=UUID=${ROOT_UUID} rootflags=subvol=@ rw quiet splash
EOF

cat > "$MP/boot/loader/entries/harnessOS-fallback.conf" <<EOF
title   HarnessOS (linux-zen, fallback)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen-fallback.img
options root=UUID=${ROOT_UUID} rootflags=subvol=@ rw
EOF

cat > "$MP/boot/loader/loader.conf" <<EOF
default harnessOS.conf
timeout 3
console-mode auto
editor  no
EOF

[[ -f "$MP/boot/vmlinuz-linux-zen" ]]        || die "vmlinuz-linux-zen not found on ESP"
[[ -f "$MP/boot/initramfs-linux-zen.img" ]]  || die "initramfs-linux-zen.img not found on ESP"
ok "Bootloader installed"

# ── 12. Snapper ──────────────────────────────────────────────────────────────
info "Step 12/13 — Configuring snapper ..."
arch-chroot "$MP" snapper -c root create-config / 2>/dev/null || true
ok "Snapper configured"

# ── 13. Dotfiles ─────────────────────────────────────────────────────────────
info "Step 13/13 — Deploying HarnessOS configs ..."
if [[ -d "/home/harness" ]]; then
    cp -r /home/harness/. "$MP/home/$USERNAME/" 2>/dev/null || true
    arch-chroot "$MP" chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/"
    ok "Dotfiles deployed from live user"
else
    warn "Live harness user not found — skipping dotfiles"
fi

# Copy HarnessOS scripts
if [[ -d "/usr/local/bin" ]]; then
    for f in harness harness-ai harness-install harness-detect-gpu harness-power \
              harness-welcome harness-online-setup harness-easter-egg \
              harness-keyboard harness-ollama-status; do
        [[ -f "/usr/local/bin/$f" ]] && cp "/usr/local/bin/$f" "$MP/usr/local/bin/$f"
    done
    chmod +x "$MP"/usr/local/bin/harness*
fi

# Copy installer
if [[ -d "/usr/local/lib/harness" ]]; then
    cp -r /usr/local/lib/harness "$MP/usr/local/lib/"
fi

# Copy easter egg assets
if [[ -d "/usr/local/share/harness" ]]; then
    mkdir -p "$MP/usr/local/share/"
    cp -r /usr/local/share/harness "$MP/usr/local/share/"
fi

# Copy wallpaper/branding assets — referenced by hyprland.conf's swaybg exec-once
if [[ -d "/usr/share/harness" ]]; then
    mkdir -p "$MP/usr/share/"
    cp -r /usr/share/harness "$MP/usr/share/"
fi

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   HarnessOS installed successfully!      ║"
echo "  ║                                          ║"
echo "  ║   Remove USB and reboot:                 ║"
echo "  ║     umount -R /mnt && reboot             ║"
echo "  ║                                          ║"
echo "  ║   First login → harness setup            ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RST}"
echo "  Full log: $LOG"
