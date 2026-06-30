"""HarnessOS — systemd-boot installation"""
import re
import subprocess
from pathlib import Path

from . import disk as disk_core

EFI_BOOT_LABEL = "HarnessOS"


def _disk_and_partnum(part_path: str) -> tuple[str, str]:
    """Split a partition device path (/dev/sda1, /dev/nvme0n1p1) into (disk, partition number)."""
    m = re.match(r"^(/dev/(?:[a-z]+|nvme\d+n\d+))p?(\d+)$", part_path)
    if not m:
        raise RuntimeError(f"Could not parse disk/partition number from {part_path!r}")
    return m.group(1), m.group(2)


def _ensure_efi_boot_entry(efi_part: str) -> None:
    """`bootctl install` run inside arch-chroot can copy the loader files to
    the ESP but silently fail to register the NVRAM boot entry — chroots
    don't always get full EFI variable write access. Without an NVRAM entry
    the firmware has nothing telling it to boot this disk, even though every
    file on the ESP is correct. Create the entry explicitly rather than
    trusting bootctl did it.
    """
    existing = subprocess.run(["efibootmgr"], capture_output=True, text=True)
    if re.search(rf"^\S+\* {re.escape(EFI_BOOT_LABEL)}\b", existing.stdout, re.MULTILINE):
        return
    disk, partnum = _disk_and_partnum(efi_part)
    subprocess.run([
        "efibootmgr", "--create", "--disk", disk, "--part", partnum,
        "--label", EFI_BOOT_LABEL, "--loader", r"\EFI\systemd\systemd-bootx64.efi",
    ], check=True)


def install_bootloader(mountpoint: str, root_part: str, efi_part: str, nvidia: bool = False) -> None:
    """Install systemd-boot and create boot entries."""
    boot_dir = str(Path(mountpoint) / "boot")
    disk_core.assert_mounted(boot_dir, "EFI System Partition")

    subprocess.run(
        ["arch-chroot", mountpoint, "bootctl", "--path=/boot", "install"],
        check=True,
    )
    _ensure_efi_boot_entry(efi_part)

    mp = Path(mountpoint)
    loader_dir = mp / "boot" / "loader"
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


def verify_bootloader(mountpoint: str) -> None:
    """Confirm the boot entry actually resolves from the ESP, not the root subvolume.

    Catches the failure mode in docs/07-known-issues.md: bootctl binaries land
    on the ESP but the kernel/initrd/entry get written to the parent filesystem
    because the ESP wasn't mounted when those files were created.
    """
    boot_dir = str(Path(mountpoint) / "boot")
    disk_core.assert_mounted(boot_dir, "EFI System Partition")

    for required in ("vmlinuz-linux-zen", "initramfs-linux-zen.img", "loader/entries/harnessOS.conf"):
        if not (Path(mountpoint) / "boot" / required).is_file():
            raise RuntimeError(
                f"Expected {required} on the ESP after bootloader install but it's missing — "
                "boot files may have been written before the ESP was mounted."
            )

    result = subprocess.run(
        ["arch-chroot", mountpoint, "bootctl", "status"],
        capture_output=True, text=True,
    )
    if "harnessOS.conf" not in result.stdout or "EFI System Partition" not in result.stdout:
        raise RuntimeError(
            "bootctl status doesn't report the HarnessOS entry sourced from the ESP:\n"
            f"{result.stdout}\n{result.stderr}"
        )

    efi_entries = subprocess.run(["efibootmgr"], capture_output=True, text=True)
    if not re.search(rf"^\S+\* {re.escape(EFI_BOOT_LABEL)}\b", efi_entries.stdout, re.MULTILINE):
        raise RuntimeError(
            "No NVRAM boot entry found for HarnessOS — the loader files are on the "
            "ESP but the firmware has nothing telling it to boot this disk. "
            f"efibootmgr output:\n{efi_entries.stdout}{efi_entries.stderr}"
        )
