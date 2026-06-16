"""HarnessOS Installer — Confirmation Screen"""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Button
from textual.containers import Vertical, Horizontal


class ConfirmScreen(Screen):
    CSS = """
    #warning {
        color: #f7768e;
        text-style: bold;
        border: solid #f7768e;
        padding: 1;
        margin: 1 0;
    }
    #summary {
        color: #9ece6a;
        border: solid #414868;
        padding: 1;
    }
    """

    def on_mount(self) -> None:
        cfg = self.app.config
        gpu_info = "No GPU driver changes"
        if cfg.install_nvidia:
            gpu_info = f"NVIDIA drivers (nvidia-dkms)" + (" + CUDA" if cfg.install_cuda else "")
        elif cfg.install_rocm:
            gpu_info = "AMD ROCm"

        summary = (
            f"Disk    : {cfg.disk}\n"
            f"Hostname: {cfg.hostname}\n"
            f"User    : {cfg.username}\n"
            f"Timezone: {cfg.timezone}\n"
            f"Locale  : {cfg.locale}\n"
            f"GPU     : {gpu_info}\n"
            f"Extras  : {', '.join(cfg.extra_packages) or 'none'}\n"
        )
        self.query_one("#summary", Static).update(summary)

    def compose(self) -> ComposeResult:
        cfg = self.app.config
        yield Vertical(
            Static("Confirm Installation", classes="screen-title"),
            Static(
                f"⚠  THIS WILL PERMANENTLY ERASE ALL DATA ON {self.app.config.disk}\n"
                "This action cannot be undone.",
                id="warning",
            ),
            Static("", id="summary"),
            Horizontal(
                Button("← Back",           id="btn-back",    variant="default"),
                Button("Install HarnessOS", id="btn-install", variant="error"),
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-back":
            self.app.pop_screen()
        elif event.button.id == "btn-install":
            self.app.push_screen("progress")
