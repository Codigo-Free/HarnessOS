"""HarnessOS Installer — Software Profile Screen"""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Button, Checkbox
from textual.containers import Vertical, Horizontal


class SoftwareProfileScreen(Screen):
    def compose(self) -> ComposeResult:
        yield Vertical(
            Static("Software Profile", classes="screen-title"),
            Static("Select additional packages to install:"),
            Checkbox("Full AI Dev Stack (Claude CLI, Ollama, Copilot, Docker) — recommended", id="cb-ai",     value=True),
            Checkbox("Node.js / Frontend (nodejs, npm, pnpm, typescript, ts-node)",           id="cb-node",   value=True),
            Checkbox("Python (python3, pip, pipx, uv, virtualenv)",                           id="cb-python", value=True),
            Checkbox("Java (jdk-openjdk, maven)",                                             id="cb-java",   value=True),
            Checkbox("C# / .NET SDK",                                                         id="cb-dotnet", value=True),
            Checkbox("PHP + Composer",                                                        id="cb-php",    value=False),
            Checkbox("Rust (rustup)",                                                         id="cb-rust",   value=False),
            Horizontal(
                Button("← Back", id="btn-back", variant="default"),
                Button("Next →", id="btn-next", variant="primary"),
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-back":
            self.app.pop_screen()
        elif event.button.id == "btn-next":
            extras: list[str] = []
            if self.query_one("#cb-rust", Checkbox).value:
                extras.append("rustup")
            if self.query_one("#cb-php", Checkbox).value:
                extras.extend(["php", "php-fpm", "composer"])
            self.app.config.extra_packages = extras
            self.app.push_screen("confirm")
