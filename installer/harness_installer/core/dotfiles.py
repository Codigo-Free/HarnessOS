"""HarnessOS — Deploy dotfiles to the installed system."""
import shutil
import subprocess
from pathlib import Path


LIVE_HOME = Path("/home/harness")
LIVE_CONFIGS = [
    ".config/hypr",
    ".config/waybar",
    ".config/kitty",
    ".config/wofi",
    ".zshrc",
    ".zprofile",
]


def deploy_dotfiles(mountpoint: str, username: str) -> None:
    """Copy dotfiles from live harness user to the installed user's home."""
    target_home = Path(mountpoint) / "home" / username

    for item in LIVE_CONFIGS:
        src = LIVE_HOME / item
        dst = target_home / item
        if not src.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)

    # Fix ownership — uid/gid are resolved from the chroot /etc/passwd
    result = subprocess.run(
        ["arch-chroot", mountpoint, "id", "-u", username],
        capture_output=True, text=True,
    )
    uid = result.stdout.strip() if result.returncode == 0 else "1000"
    subprocess.run(
        ["chown", "-R", f"{uid}:{uid}", str(target_home)],
        check=True,
    )
