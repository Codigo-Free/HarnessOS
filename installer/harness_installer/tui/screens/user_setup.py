"""HarnessOS Installer — User Setup Screen"""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Input, Button, Label, Static
from textual.containers import Vertical, Horizontal


class UserSetupScreen(Screen):
    def compose(self) -> ComposeResult:
        yield Vertical(
            Static("User & System Configuration", classes="screen-title"),
            Label("Hostname:"),
            Input(value="harnessOS", id="hostname", placeholder="harnessOS"),
            Label("Username:"),
            Input(id="username", placeholder="your-username"),
            Label("Password:"),
            Input(id="password", password=True, placeholder="••••••••"),
            Label("Confirm Password:"),
            Input(id="password-confirm", password=True, placeholder="••••••••"),
            Label("Timezone (e.g. America/New_York):"),
            Input(value="UTC", id="timezone", placeholder="UTC"),
            Label("Locale (e.g. en_US.UTF-8 UTF-8):"),
            Input(value="en_US.UTF-8 UTF-8", id="locale"),
            Horizontal(
                Button("← Back", id="btn-back",  variant="default"),
                Button("Next →", id="btn-next",  variant="primary"),
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-back":
            self.app.pop_screen()
        elif event.button.id == "btn-next":
            hostname = self.query_one("#hostname", Input).value.strip()
            username = self.query_one("#username", Input).value.strip()
            password = self.query_one("#password", Input).value
            confirm  = self.query_one("#password-confirm", Input).value
            timezone = self.query_one("#timezone", Input).value.strip()
            locale   = self.query_one("#locale", Input).value.strip()

            if not hostname or not username or not password:
                self.notify("All fields are required.", severity="error")
                return
            if password != confirm:
                self.notify("Passwords do not match.", severity="error")
                return

            cfg = self.app.config
            cfg.hostname = hostname
            cfg.username = username
            cfg.password = password
            cfg.timezone = timezone
            cfg.locale   = locale
            self.app.push_screen("gpu")
