"""HarnessOS — Disk partitioning and BTRFS subvolume setup"""
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

MOUNT_OPTIONS = "noatime,compress=zstd:1,space_cache=v2"

BTRFS_SUBVOLUMES: list[tuple[str, str]] = [
    ("@",           "/"),
    ("@home",       "/home"),
    ("@var",        "/var"),
    ("@var_log",    "/var/log"),
    ("@snapshots",  "/.snapshots"),
    ("@swap",       "/swap"),
]


def list_disks() -> list[dict]:
    """Return list of available block devices."""
    result = subprocess.run(
        ["lsblk", "-d", "-n", "-o", "NAME,SIZE,MODEL,TRAN"],
        capture_output=True, text=True, check=True,
    )
    disks = []
    for line in result.stdout.strip().splitlines():
        parts = line.split(maxsplit=3)
        if not parts:
            continue
        name = parts[0]
        if any(skip in name for skip in ("loop", "sr", "zram", "ram")):
            continue
        disks.append({
            "path":  f"/dev/{name}",
            "size":  parts[1] if len(parts) > 1 else "?",
            "model": parts[2] if len(parts) > 2 else "Unknown",
            "tran":  parts[3] if len(parts) > 3 else "?",
        })
    return disks


def _run(cmd: list[str]) -> None:
    result = subprocess.run(cmd, capture_output=True, text=True)
    _log_to_file(f"$ {' '.join(cmd)}")
    if result.stdout:
        _log_to_file(result.stdout.strip())
    if result.stderr:
        _log_to_file(result.stderr.strip())
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd, result.stdout, result.stderr)


def _log_to_file(msg: str) -> None:
    try:
        with open("/tmp/harness-install.log", "a") as f:
            f.write(msg + "\n")
    except Exception:
        pass


def partition_disk(disk: str) -> tuple[str, str]:
    """Wipe and partition disk with GPT: 512M EFI + rest BTRFS root.

    Returns (efi_partition_path, root_partition_path).
    """
    _run(["wipefs", "-af", disk])
    _run([
        "sgdisk", disk,
        "-n", "1:0:+512M", "-t", "1:ef00", "-c", "1:EFI",
        "-n", "2:0:0",     "-t", "2:8300", "-c", "2:ROOT",
    ])
    _run(["partprobe", disk])
    time.sleep(1)

    if "nvme" in disk:
        return f"{disk}p1", f"{disk}p2"
    return f"{disk}1", f"{disk}2"


def format_partitions(efi: str, root: str) -> None:
    _run(["mkfs.fat", "-F32", "-n", "EFI", efi])
    _run(["mkfs.btrfs", "-f", "-L", "HarnessOS", root])


def create_btrfs_subvolumes(root_part: str, mountpoint: str = "/mnt") -> None:
    """Mount BTRFS, create subvolumes, remount each at its target path."""
    mp = Path(mountpoint)
    mp.mkdir(exist_ok=True)
    _run(["mount", root_part, mountpoint])

    for subvol, _ in BTRFS_SUBVOLUMES:
        _run(["btrfs", "subvolume", "create", f"{mountpoint}/{subvol}"])

    _run(["umount", mountpoint])

    for subvol, target in BTRFS_SUBVOLUMES:
        target_path = mp / target.lstrip("/")
        target_path.mkdir(parents=True, exist_ok=True)
        opts = f"{MOUNT_OPTIONS},subvol={subvol}"
        _run(["mount", "-o", opts, root_part, str(target_path)])

    # Disable CoW on swap subvolume — required for BTRFS swapfile
    _run(["chattr", "+C", str(mp / "swap")])


def create_swapfile(mountpoint: str, size_gb: int = 4) -> None:
    swap_path = Path(mountpoint) / "swap" / "swapfile"
    _run(["btrfs", "filesystem", "mkswapfile", f"--size={size_gb}g", str(swap_path)])
    _run(["swapon", str(swap_path)])


def mount_efi(efi_part: str, mountpoint: str = "/mnt") -> None:
    efi_dir = Path(mountpoint) / "boot" / "efi"
    efi_dir.mkdir(parents=True, exist_ok=True)
    _run(["mount", efi_part, str(efi_dir)])


def generate_fstab(mountpoint: str) -> None:
    result = subprocess.run(["genfstab", "-U", mountpoint], capture_output=True, text=True, check=True)
    fstab_path = Path(mountpoint) / "etc" / "fstab"
    with fstab_path.open("a") as f:
        f.write(result.stdout)
