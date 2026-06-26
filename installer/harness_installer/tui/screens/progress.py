"""HarnessOS Installer — Installation Progress Screen"""
import threading
import os
from datetime import datetime
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Log, ProgressBar
from textual.containers import Vertical

from harness_installer.core import disk as disk_core
from harness_installer.core import chroot as chroot_core
from harness_installer.core import gpu as gpu_core
from harness_installer.core import bootloader as boot_core
from harness_installer.core import snapshots as snap_core
from harness_installer.core import dotfiles as dotfiles_core

LOG_FILE = "/tmp/harness-install.log"

STEPS = [
    "Partitioning disk",
    "Formatting partitions",
    "Creating BTRFS subvolumes",
    "Creating swapfile",
    "Running pacstrap",
    "Configuring system",
    "Creating user",
    "Installing GPU drivers",
    "Installing bootloader",
    "Configuring snapper",
    "Installing npm globals (Claude CLI, pnpm, TypeScript)",
    "Deploying dotfiles",
    "Generating fstab",
    "Done!",
]


class ProgressScreen(Screen):
    CSS = """
    #title {
        color: #7aa2f7;
        text-style: bold;
        margin-bottom: 1;
    }
    #step-label {
        color: #9ece6a;
    }
    ProgressBar {
        margin: 1 0;
    }
    Log {
        height: 20;
        border: solid #414868;
    }
    """

    def compose(self) -> ComposeResult:
        yield Vertical(
            Static("Installing HarnessOS...", id="title"),
            Static("Preparing...", id="step-label"),
            ProgressBar(total=len(STEPS), show_eta=False, id="progress"),
            Log(id="install-log", auto_scroll=True),
        )

    def on_mount(self) -> None:
        open(LOG_FILE, "w").close()
        threading.Thread(target=self._run_install, daemon=True).start()

    def _log(self, msg: str) -> None:
        try:
            with open(LOG_FILE, "a") as f:
                ts = datetime.now().isoformat(timespec="seconds")
                f.write(f"[{ts}] {msg}\n")
        except Exception:
            pass

        try:
            self.query_one("#install-log", Log).write_line(msg)
        except Exception:
            pass

    def _set_step(self, step: str, n: int) -> None:
        self._log(f">>> STEP {n}/{len(STEPS)}: {step}")
        try:
            self.query_one("#step-label", Static).update(f"Step {n}/{len(STEPS)}: {step}")
        except Exception:
            pass
        try:
            self.query_one("#progress", ProgressBar).advance(1)
        except Exception:
            pass

    def _set_label(self, text: str) -> None:
        self._log(text)
        try:
            self.query_one("#step-label", Static).update(text)
        except Exception:
            pass

    def _run_install(self) -> None:
        cfg = self.app.config
        mp  = "/mnt"

        try:
            if not isinstance(cfg.disk, str) or not cfg.disk:
                raise ValueError(f"No disk selected (got {cfg.disk!r})")

            self._set_step("Partitioning disk", 1)
            self._log(f"Partitioning {cfg.disk}...")
            efi, root = disk_core.partition_disk(cfg.disk)
            cfg.efi_part  = efi
            cfg.root_part = root

            self._set_step("Formatting partitions", 2)
            self._log("Formatting EFI (FAT32) and root (BTRFS)...")
            disk_core.format_partitions(efi, root)

            self._set_step("Creating BTRFS subvolumes", 3)
            self._log("Creating @ @home @var @var_log @snapshots @swap...")
            disk_core.create_btrfs_subvolumes(root, mp)

            self._set_step("Creating swapfile", 4)
            self._log(f"Creating {cfg.swap_gb}GB swapfile...")
            disk_core.create_swapfile(mp, cfg.swap_gb)
            disk_core.mount_efi(efi, mp)

            self._set_step("Running pacstrap", 5)
            self._log("Installing base packages (this takes a few minutes)...")
            chroot_core.pacstrap(mp, cfg.extra_packages)

            self._set_step("Configuring system", 6)
            self._log("Setting hostname, locale, timezone, enabling services...")
            chroot_core.configure_system(mp, cfg.hostname, cfg.locale, cfg.timezone)

            self._set_step("Creating user", 7)
            self._log(f"Creating user '{cfg.username}'...")
            chroot_core.create_user(mp, cfg.username, cfg.password)

            self._set_step("Installing GPU drivers", 8)
            if cfg.install_nvidia:
                self._log("Installing NVIDIA drivers + CUDA...")
                gpu_core.install_nvidia_drivers(mp, install_cuda=cfg.install_cuda)
            elif cfg.gpu_vendor == "amd":
                self._log("Installing AMD Mesa drivers...")
                gpu_core.install_amd_drivers(mp)
            else:
                self._log("Intel/no discrete GPU — skipping proprietary drivers.")

            self._set_step("Installing bootloader", 9)
            self._log("Installing systemd-boot...")
            boot_core.install_bootloader(mp, cfg.root_part, nvidia=cfg.install_nvidia)

            self._set_step("Configuring snapper", 10)
            self._log("Setting up BTRFS snapshots with snapper...")
            snap_core.configure_snapper(mp)

            self._set_step("Installing npm globals", 11)
            self._log("Installing Claude CLI, pnpm, TypeScript...")
            chroot_core.install_npm_globals(mp)

            self._set_step("Deploying dotfiles", 12)
            self._log(f"Copying Hyprland, waybar, kitty configs to /home/{cfg.username}...")
            dotfiles_core.deploy_dotfiles(mp, cfg.username)

            self._set_step("Generating fstab", 13)
            self._log("Generating /etc/fstab...")
            disk_core.generate_fstab(mp)

            self._set_step("Done!", 14)
            self._log("")
            self._log("✓ HarnessOS installed successfully!")
            self._log("  Remove the installation media and reboot.")
            self._log(f"  First login: user = {cfg.username}")
            self._log("  Hyprland starts automatically on first login.")
            self._set_label("Installation complete! You can now reboot.")

        except Exception as exc:
            import traceback
            self._log(f"\n✗ Installation failed: {exc}")
            self._log(traceback.format_exc())
            self._set_label(f"Error: {exc}")
