"""HarnessOS Installer — Disk Setup Screen"""
from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Static, Button, Select, Label
from textual.containers import Vertical, Horizontal

from harness_installer.core.disk import list_disks

BTRFS_LAYOUT = """
BTRFS Subvolume Layout (fixed):
  @           →  /
  @home       →  /home
  @var        →  /var
  @var_log    →  /var/log
  @snapshots  →  /.snapshots
  @swap       →  /swap  (CoW disabled)

EFI: 512 MB  |  Root: remaining space
"""


class DiskSetupScreen(Screen):
    CSS = """
    #layout-info {
        color: #e0af68;
        border: solid #414868;
        padding: 1;
        margin: 1 0;
    }
    #warning {
        color: #f7768e;
        text-style: bold;
    }
    """

    def compose(self) -> ComposeResult:
        disks = list_disks()
        options = [(f"{d['path']}  {d['size']}  {d['model']}", d["path"]) for d in disks]

        yield Vertical(
            Static("Select Installation Disk", classes="screen-title"),
            Static("⚠  ALL DATA ON THE SELECTED DISK WILL BE ERASED", id="warning"),
            Select(options, id="disk-select", prompt="Choose a disk..."),
            Static(BTRFS_LAYOUT, id="layout-info"),
            Horizontal(
                Button("← Back",   id="btn-back",    variant="default"),
                Button("Next →",   id="btn-next",    variant="primary"),
            ),
        )

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "btn-back":
            self.app.pop_screen()
        elif event.button.id == "btn-next":
            disk_widget = self.query_one("#disk-select", Select)
            value = disk_widget.value
            if value is Select.BLANK or not isinstance(value, str):
                self.notify("Please select a disk first.", severity="error")
                return
            self.app.config.disk = value
            self.app.push_screen("user")
