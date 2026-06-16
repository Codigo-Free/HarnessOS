"""HarnessOS — Snapper configuration for BTRFS snapshots"""
import re
import subprocess
from pathlib import Path


SNAPPER_SETTINGS = {
    "TIMELINE_CREATE":       '"yes"',
    "TIMELINE_CLEANUP":      '"yes"',
    "TIMELINE_LIMIT_HOURLY": '"10"',
    "TIMELINE_LIMIT_DAILY":  '"7"',
    "TIMELINE_LIMIT_WEEKLY": '"4"',
    "TIMELINE_LIMIT_MONTHLY": '"3"',
    "TIMELINE_LIMIT_YEARLY": '"0"',
}


def configure_snapper(mountpoint: str) -> None:
    """Create snapper root config and enable timers."""
    # Create config (--no-dbus required inside chroot)
    subprocess.run(
        ["arch-chroot", mountpoint,
         "snapper", "--no-dbus", "-c", "root", "create-config", "/"],
        check=True,
    )

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
        subprocess.run(
            ["arch-chroot", mountpoint, "systemctl", "enable", svc],
            check=True,
        )
