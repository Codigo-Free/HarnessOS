"""HarnessOS — pacstrap and arch-chroot wrappers"""
import subprocess
import shlex
from pathlib import Path


BASE_PACKAGES = [
    "base", "base-devel", "linux-zen", "linux-zen-headers", "linux-firmware",
    "mkinitcpio", "systemd-boot", "efibootmgr", "networkmanager", "bluez",
    "btrfs-progs", "snapper", "snap-pac",
    "zsh", "git", "curl", "wget", "vim", "neovim", "htop",
    "docker", "docker-compose", "docker-buildx",
    "python", "python-pip", "python-pipx", "uv",
    "nodejs", "npm",
    "dotnet-sdk", "jdk-openjdk", "php", "php-fpm",
    "ollama", "gh",
    "hyprland", "waybar", "kitty", "wofi", "swaync",
    "pipewire", "pipewire-alsa", "pipewire-pulse", "wireplumber",
    "ttf-jetbrains-mono-nerd", "ttf-font-awesome",
    "stow", "fzf", "ripgrep", "fd", "bat", "eza", "zoxide", "lazygit",
    "starship", "zsh-autosuggestions", "zsh-syntax-highlighting",
]


def pacstrap(mountpoint: str, extra_packages: list[str] | None = None) -> None:
    packages = list(BASE_PACKAGES)
    if extra_packages:
        packages.extend(extra_packages)
    subprocess.run(
        ["pacstrap", "-K", mountpoint] + packages,
        check=True,
    )


def chroot_run(mountpoint: str, command: str | list[str]) -> None:
    if isinstance(command, str):
        cmd = ["arch-chroot", mountpoint, "/bin/bash", "-c", command]
    else:
        cmd = ["arch-chroot", mountpoint] + command
    subprocess.run(cmd, check=True)


def configure_system(mountpoint: str, hostname: str, locale: str, timezone: str) -> None:
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
    # Set password via chpasswd
    proc = subprocess.run(
        ["arch-chroot", mountpoint, "chpasswd"],
        input=f"{username}:{password}\n",
        text=True,
        check=True,
    )


def install_npm_globals(mountpoint: str) -> None:
    chroot_run(mountpoint, "npm install -g @anthropic-ai/claude-code pnpm typescript ts-node")
    chroot_run(mountpoint, "gh extension install github/gh-copilot 2>/dev/null || true")
