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
    ".config/opencode",   # OpenCode → local Ollama + harness-mcp
    ".config/harness",    # model routing written by harness-tune-ai (if it ran)
    ".continue",          # Continue (VS Code) → local Ollama
    ".zshrc",
    ".zprofile",
]

LIVE_SHARE = Path("/usr/share/harness")


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


def deploy_branding(mountpoint: str) -> None:
    """Copy system-wide branding assets (wallpaper, logo) baked into the
    live airootfs at /usr/share/harness — hyprland.conf's swaybg exec-once
    references this path, so without this the installed system boots with
    no wallpaper."""
    if not LIVE_SHARE.exists():
        return
    target_share = Path(mountpoint) / "usr" / "share" / "harness"
    target_share.parent.mkdir(parents=True, exist_ok=True)
    if target_share.exists():
        shutil.rmtree(target_share)
    shutil.copytree(LIVE_SHARE, target_share)


def deploy_cli_tools(mountpoint: str) -> None:
    """Copy the harness-* CLI toolkit baked into the live airootfs to the
    installed system. None of /usr/local/bin/harness*, /usr/local/lib/harness
    or /usr/local/share/harness are part of any pacman package — they only
    exist via the ISO's airootfs overlay — so without this step `harness`,
    `harness-ai`, `harness-easter-egg`, `harness-ollama-status`, etc. are
    silently absent on the installed system (waybar/hyprland keybinds that
    reference them just fail with no error)."""
    mp = Path(mountpoint)

    bin_src = Path("/usr/local/bin")
    bin_dst = mp / "usr" / "local" / "bin"
    bin_dst.mkdir(parents=True, exist_ok=True)
    for item in bin_src.glob("harness*"):
        shutil.copy2(item, bin_dst / item.name)
        (bin_dst / item.name).chmod(0o755)

    for name in ("lib", "share"):
        src = Path("/usr/local") / name / "harness"
        if not src.exists():
            continue
        dst = mp / "usr" / "local" / name / "harness"
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)

    # harness-online-setup.service only exists via the ISO's airootfs
    # overlay, so without copying + enabling it here the installed system
    # never gets Claude Code, OpenCode, yay, the tuned AI models or the
    # harness-mcp registration — none of that is in any pacman package.
    # Enable = wants-symlink; systemctl isn't usable against a mountpoint
    # this early and the unit's ConditionPathExists guards re-runs.
    unit_src = Path("/etc/systemd/system/harness-online-setup.service")
    if unit_src.exists():
        unit_dst = mp / "etc" / "systemd" / "system" / unit_src.name
        unit_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(unit_src, unit_dst)
        wants = mp / "etc" / "systemd" / "system" / "multi-user.target.wants"
        wants.mkdir(parents=True, exist_ok=True)
        link = wants / unit_src.name
        if not link.is_symlink():
            link.symlink_to(f"/etc/systemd/system/{unit_src.name}")
