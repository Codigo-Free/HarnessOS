"""HarnessOS Installer — GPU Setup Screen"""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Button, Checkbox, Label
from textual.containers import Vertical, Horizontal

from harness_installer.core.gpu import detect_gpu_vendor, detect_nvidia_model, get_recommended_driver


class GpuSetupScreen(Screen):
    CSS = """
    #gpu-info {
        color: #7dcfff;
        border: solid #414868;
        padding: 1;
        margin: 1 0;
    }
    """

    def on_mount(self) -> None:
        self.vendor = detect_gpu_vendor()
        self.app.config.gpu_vendor = self.vendor

        gpu_label = self.query_one("#gpu-info", Static)
        if self.vendor == "nvidia":
            model = detect_nvidia_model()
            driver = get_recommended_driver()
            gpu_label.update(f"Detected GPU: NVIDIA {model}\nRecommended driver: {driver}")
            self.query_one("#cb-nvidia", Checkbox).value = True
            self.query_one("#cb-cuda", Checkbox).value = True
        elif self.vendor == "amd":
            gpu_label.update("Detected GPU: AMD\nDriver: mesa (open-source)")
        else:
            gpu_label.update("GPU: Intel / Unknown\nDriver: mesa (open-source)")

    def compose(self) -> ComposeResult:
        yield Vertical(
            Static("GPU & Drivers", classes="screen-title"),
            Static("Detecting GPU...", id="gpu-info"),
            Checkbox("Install NVIDIA proprietary drivers (nvidia-dkms)", id="cb-nvidia", value=False),
            Checkbox("Install CUDA toolkit + cuDNN (required for local AI training)", id="cb-cuda", value=False),
            Checkbox("Install AMD ROCm (optional, large download)", id="cb-rocm", value=False),
            Label("Note: NVIDIA drivers are NOT baked into the live ISO.\nThey are installed fresh for your hardware.", classes="hint"),
            Horizontal(
                Button("← Back", id="btn-back", variant="default"),
                Button("Next →", id="btn-next", variant="primary"),
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-back":
            self.app.pop_screen()
        elif event.button.id == "btn-next":
            self.app.config.install_nvidia = self.query_one("#cb-nvidia", Checkbox).value
            self.app.config.install_cuda   = self.query_one("#cb-cuda",   Checkbox).value
            self.app.config.install_rocm   = self.query_one("#cb-rocm",   Checkbox).value
            self.app.push_screen("software")
