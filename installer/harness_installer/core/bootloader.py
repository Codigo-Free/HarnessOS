"""HarnessOS — systemd-boot installation"""
import subprocess
from pathlib import Path


def install_bootloader(mountpoint: str, root_part: str, nvidia: bool = False) -> None:
    """Install systemd-boot and create boot entries."""
    subprocess.run(
        ["arch-chroot", mountpoint, "bootctl", "--path=/boot/efi", "install"],
        check=True,
    )

    mp = Path(mountpoint)
    loader_dir = mp / "boot" / "efi" / "loader"
    entries_dir = loader_dir / "entries"
    entries_dir.mkdir(parents=True, exist_ok=True)

    # loader.conf
    (loader_dir / "loader.conf").write_text(
        "default harnessOS.conf\n"
        "timeout 3\n"
        "console-mode auto\n"
        "editor  no\n"
    )

    # Get root partition UUID
    result = subprocess.run(
        ["blkid", "-s", "UUID", "-o", "value", root_part],
        capture_output=True, text=True, check=True,
    )
    root_uuid = result.stdout.strip()

    # BTRFS root options
    root_opts = f"root=UUID={root_uuid} rootflags=subvol=@ rw quiet loglevel=3 systemd.show_status=auto"

    # NVIDIA-specific kernel parameters
    if nvidia:
        root_opts += " nvidia-drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"

    # Boot entry
    (entries_dir / "harnessOS.conf").write_text(
        f"title   HarnessOS\n"
        f"linux   /vmlinuz-linux-zen\n"
        f"initrd  /initramfs-linux-zen.img\n"
        f"options {root_opts}\n"
    )

    # Fallback entry
    (entries_dir / "harnessOS-fallback.conf").write_text(
        f"title   HarnessOS (fallback initramfs)\n"
        f"linux   /vmlinuz-linux-zen\n"
        f"initrd  /initramfs-linux-zen-fallback.img\n"
        f"options {root_opts}\n"
    )
