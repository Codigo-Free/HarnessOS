"""HarnessOS — pacstrap and arch-chroot wrappers"""
import re
import subprocess
import shlex
from pathlib import Path


BASE_PACKAGES = [
    # Base system
    "base", "base-devel", "linux-zen", "linux-zen-headers", "linux-firmware",
    "mkinitcpio", "efibootmgr", "networkmanager", "bluez",
    "btrfs-progs", "snapper", "snap-pac", "sudo",
    # Editors & shell
    "zsh", "git", "curl", "wget", "nano", "vim", "neovim", "htop",
    # Containers
    "docker", "docker-compose", "docker-buildx",
    # Languages
    "python", "python-pip", "python-pipx",
    "nodejs", "npm",
    "jdk-openjdk",
    # AI
    "ollama", "gh",
    # Desktop
    "hyprland", "waybar", "kitty", "wofi", "swaync",
    "pipewire", "pipewire-alsa", "pipewire-pulse", "wireplumber",
    "xdg-desktop-portal-hyprland", "polkit-kde-agent", "swaybg",
    # Fonts
    "ttf-jetbrains-mono-nerd", "ttf-font-awesome",
    # TUI tools
    "stow", "fzf", "ripgrep", "fd", "bat", "eza", "zoxide", "lazygit",
    "starship", "zsh-autosuggestions", "zsh-syntax-highlighting",
    "yazi", "bottom", "lnav",
]


LOG_FILE = "/var/log/harness-install.log"


def _log(msg: str) -> None:
    try:
        with open(LOG_FILE, "a") as f:
            f.write(msg + "\n")
    except Exception:
        pass


def _run_logged(cmd: list[str]) -> None:
    _log(f"$ {' '.join(str(c) for c in cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stdout:
        _log(result.stdout.strip())
    if result.stderr:
        _log(result.stderr.strip())
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd, result.stdout, result.stderr)


def pacstrap(mountpoint: str, extra_packages: list[str] | None = None) -> None:
    packages = list(BASE_PACKAGES)
    if extra_packages:
        packages.extend(extra_packages)
    cmd = ["pacstrap", "-K", mountpoint] + packages
    _log(f"$ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stdout:
        _log(result.stdout.strip())
    if result.stderr:
        _log(result.stderr.strip())
    if result.returncode != 0:
        reason = _pacstrap_failure_reason(result.stdout, result.stderr)
        raise RuntimeError(
            f"pacstrap failed ({reason}). See {LOG_FILE} for full output."
        ) from subprocess.CalledProcessError(result.returncode, cmd, result.stdout, result.stderr)


def _pacstrap_failure_reason(stdout: str, stderr: str) -> str:
    """Best-effort extraction of *which* package/step pacstrap died on."""
    errors = re.findall(r"^error:.*$", stderr, re.MULTILINE)
    if errors:
        return "; ".join(errors[:3])
    installed = re.findall(r"^installing (\S+)", stdout, re.MULTILINE)
    if installed:
        return f"stopped after installing {len(installed)} package(s), last was {installed[-1]}"
    return "no error detail captured — check raw pacstrap output"


def chroot_run(mountpoint: str, command: str | list[str]) -> None:
    if isinstance(command, str):
        cmd = ["arch-chroot", mountpoint, "/bin/bash", "-c", command]
    else:
        cmd = ["arch-chroot", mountpoint] + list(command)
    _run_logged(cmd)


def configure_system(
    mountpoint: str,
    hostname: str,
    locale: str,
    timezone: str,
    keymap: str = "es",
) -> None:
    mp = Path(mountpoint)

    # Hostname
    (mp / "etc" / "hostname").write_text(f"{hostname}\n")
    (mp / "etc" / "hosts").write_text(
        f"127.0.0.1\tlocalhost\n"
        f"::1\t\tlocalhost\n"
        f"127.0.1.1\t{hostname}.localdomain\t{hostname}\n"
    )

    # Locale
    locale_gen = mp / "etc" / "locale.gen"
    content = locale_gen.read_text() if locale_gen.exists() else ""
    if f"#{locale}" in content:
        locale_gen.write_text(content.replace(f"#{locale}", locale))
    chroot_run(mountpoint, "locale-gen")
    (mp / "etc" / "locale.conf").write_text(f"LANG={locale.split()[0]}\n")

    # Keyboard / console
    (mp / "etc" / "vconsole.conf").write_text(f"KEYMAP={keymap}\nFONT=ter-v18n\n")

    # Timezone
    chroot_run(mountpoint, ["ln", "-sf", f"/usr/share/zoneinfo/{timezone}", "/etc/localtime"])
    chroot_run(mountpoint, "hwclock --systohc")

    # Enable services
    services = [
        "NetworkManager", "bluetooth", "docker", "ollama",
        "snapper-timeline.timer", "snapper-cleanup.timer",
    ]
    for svc in services:
        chroot_run(mountpoint, f"systemctl enable {svc}")


def create_user(
    mountpoint: str,
    username: str,
    password: str,
    shell: str = "/bin/zsh",
) -> None:
    chroot_run(mountpoint, [
        "useradd", "-m", "-G", "wheel,docker,audio,video,input",
        "-s", shell, username,
    ])
    subprocess.run(
        ["arch-chroot", mountpoint, "chpasswd"],
        input=f"{username}:{password}\n",
        text=True,
        check=True,
    )
    # Enable sudo for wheel group (uncomment the NOPASSWD-free line)
    sudoers_wheel = Path(mountpoint) / "etc" / "sudoers.d" / "wheel"
    sudoers_wheel.parent.mkdir(parents=True, exist_ok=True)
    sudoers_wheel.write_text("%wheel ALL=(ALL:ALL) ALL\n")
    sudoers_wheel.chmod(0o440)


def install_npm_globals(mountpoint: str) -> None:
    chroot_run(mountpoint, "npm install -g @anthropic-ai/claude-code pnpm typescript ts-node")
    chroot_run(mountpoint, "gh extension install github/gh-copilot 2>/dev/null || true")
