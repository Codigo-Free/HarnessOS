"""HarnessOS — Snapper configuration for BTRFS snapshots"""
import re
from pathlib import Path

from . import chroot as chroot_core

MOUNT_OPTIONS = "noatime,compress=zstd:1,space_cache=v2"

SNAPPER_SETTINGS = {
    "TIMELINE_CREATE":       '"yes"',
    "TIMELINE_CLEANUP":      '"yes"',
    "TIMELINE_LIMIT_HOURLY": '"10"',
    "TIMELINE_LIMIT_DAILY":  '"7"',
    "TIMELINE_LIMIT_WEEKLY": '"4"',
    "TIMELINE_LIMIT_MONTHLY": '"3"',
    "TIMELINE_LIMIT_YEARLY": '"0"',
}


def configure_snapper(mountpoint: str, root_part: str) -> None:
    """Create snapper root config and enable timers.

    disk.create_btrfs_subvolumes() already mounted the @snapshots subvolume
    at /.snapshots before pacstrap ever ran. `snapper create-config` insists
    on creating its own subvolume at that exact path and fails with
    "already exists" if it's already occupied — so swap it out: drop our
    mount, let snapper create (and populate) its own, delete that one, then
    remount our pre-existing @snapshots subvolume back in its place.
    """
    mp = Path(mountpoint)
    snapshots_dir = mp / ".snapshots"

    chroot_core._run_logged(["umount", str(snapshots_dir)])
    snapshots_dir.rmdir()

    chroot_core.chroot_run(mountpoint, [
        "snapper", "--no-dbus", "-c", "root", "create-config", "/",
    ])

    chroot_core._run_logged(["btrfs", "subvolume", "delete", str(snapshots_dir)])
    snapshots_dir.mkdir()
    chroot_core._run_logged([
        "mount", "-o", f"{MOUNT_OPTIONS},subvol=@snapshots", root_part, str(snapshots_dir),
    ])
    snapshots_dir.chmod(0o750)

    config_file = Path(mountpoint) / "etc" / "snapper" / "configs" / "root"
    if config_file.exists():
        content = config_file.read_text()
        for key, value in SNAPPER_SETTINGS.items():
            content = re.sub(
                rf"^{re.escape(key)}=.*$",
                f"{key}={value}",
                content,
                flags=re.MULTILINE,
            )
        config_file.write_text(content)

    # Enable snapper timers and snap-pac (pacman hooks)
    for svc in ("snapper-timeline.timer", "snapper-cleanup.timer"):
        chroot_core.chroot_run(mountpoint, ["systemctl", "enable", svc])
