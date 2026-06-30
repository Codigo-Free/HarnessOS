"""HarnessOS — Textual TUI Application"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional

from textual.app import App, ComposeResult
from textual.widgets import Header, Footer

from harness_installer.tui.screens.welcome import WelcomeScreen
from harness_installer.tui.screens.disk_setup import DiskSetupScreen
from harness_installer.tui.screens.user_setup import UserSetupScreen
from harness_installer.tui.screens.gpu_setup import GpuSetupScreen
from harness_installer.tui.screens.software_profile import SoftwareProfileScreen
from harness_installer.tui.screens.confirm import ConfirmScreen
from harness_installer.tui.screens.progress import ProgressScreen


@dataclass
class InstallConfig:
    disk:           str = ""
    efi_part:       str = ""
    root_part:      str = ""
    hostname:       str = "harnessOS"
    username:       str = ""
    password:       str = ""
    timezone:       str = "UTC"
    locale:         str = "es_ES.UTF-8 UTF-8"
    keymap:         str = "es"
    swap_gb:        int = 4
    gpu_vendor:     str = "unknown"
    install_nvidia: bool = False
    install_cuda:   bool = False
    install_rocm:   bool = False
    extra_packages: list[str] = field(default_factory=list)


class HarnessInstallerApp(App):
    """HarnessOS interactive installer."""

    CSS = """
    Screen {
        background: #1a1b26;
    }
    Header {
        background: #24283b;
        color: #7aa2f7;
    }
    Footer {
        background: #24283b;
        color: #565f89;
    }
    """

    TITLE = "HarnessOS Installer"
    SUB_TITLE = "AI-Powered Development Environment"

    SCREENS = {
        "welcome":  WelcomeScreen,
        "disk":     DiskSetupScreen,
        "user":     UserSetupScreen,
        "gpu":      GpuSetupScreen,
        "software": SoftwareProfileScreen,
        "confirm":  ConfirmScreen,
        "progress": ProgressScreen,
    }

    def __init__(self, preselected_disk: Optional[str] = None) -> None:
        super().__init__()
        self.config = InstallConfig()
        if preselected_disk:
            self.config.disk = preselected_disk

    def on_mount(self) -> None:
        self.push_screen("welcome")
