"""HarnessOS Installer — Welcome Screen"""
import subprocess
from pathlib import Path

from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Button
from textual.containers import Center, Vertical

from harness_installer.core.gpu import detect_gpu_vendor, detect_nvidia_model


LOGO = """
  ██╗  ██╗ █████╗ ██████╗ ███╗   ██╗███████╗███████╗███████╗
  ██║  ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝██╔════╝
  ███████║███████║██████╔╝██╔██╗ ██║█████╗  ███████╗███████╗
  ██╔══██║██╔══██║██╔══██╗██║╚██╗██║██╔══╝  ╚════██║╚════██║
  ██║  ██║██║  ██║██║  ██║██║ ╚████║███████╗███████║███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝
"""


def _cpu_info() -> str:
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "model name" in line:
                    return line.split(":")[1].strip()
    except OSError:
        pass
    return "Unknown"


def _ram_info() -> str:
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if "MemTotal" in line:
                    kb = int(line.split()[1])
                    return f"{kb // 1024 // 1024} GB"
    except OSError:
        pass
    return "Unknown"


class WelcomeScreen(Screen):
    CSS = """
    WelcomeScreen {
        align: center middle;
    }
    #logo {
        color: #7aa2f7;
        text-style: bold;
        margin-bottom: 1;
    }
    #subtitle {
        color: #9aa5ce;
        text-align: center;
    }
    #hw-info {
        color: #9ece6a;
        margin: 1 0;
    }
    #btn-start {
        background: #7aa2f7;
        color: #1a1b26;
        margin-top: 2;
    }
    """

    def compose(self) -> ComposeResult:
        vendor = detect_gpu_vendor()
        gpu_label = detect_nvidia_model() if vendor == "nvidia" else vendor.upper()

        yield Center(
            Vertical(
                Static(LOGO, id="logo"),
                Static("AI-Powered Development Environment", id="subtitle"),
                Static(
                    f"CPU: {_cpu_info()}\n"
                    f"RAM: {_ram_info()}\n"
                    f"GPU: {gpu_label}",
                    id="hw-info",
                ),
                Button("Start Installation →", id="btn-start", variant="primary"),
            )
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-start":
            self.app.push_screen("disk")
