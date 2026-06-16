#!/usr/bin/env python3
"""HarnessOS Installer — Entry point"""
import sys
import argparse
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="HarnessOS Installer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  harness-install                  # Interactive TUI installer
  harness-install --disk /dev/sda  # Pre-select target disk
""",
    )
    p.add_argument("--disk",      type=str, help="Target disk (e.g. /dev/nvme0n1)")
    p.add_argument("--headless",  action="store_true", help="Non-interactive (reads config JSON)")
    p.add_argument("--config",    type=str, help="Path to install config JSON (headless mode)")
    p.add_argument("--version",   action="version", version="HarnessOS Installer 0.1.0")
    return p.parse_args()


def check_requirements() -> None:
    """Fail fast if running in an unsupported environment."""
    if sys.platform != "linux":
        print("HarnessOS installer only runs on Linux.", file=sys.stderr)
        sys.exit(1)

    if not Path("/proc/mounts").exists():
        print("Cannot read /proc/mounts — are you in a container?", file=sys.stderr)
        sys.exit(1)

    # Must be root
    import os
    if os.geteuid() != 0:
        print("Installer must run as root. Use: sudo harness-install", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    args = parse_args()
    check_requirements()

    if args.headless:
        from harness_installer.core.headless import run_headless
        run_headless(args.config, args.disk)
    else:
        from harness_installer.tui.app import HarnessInstallerApp
        app = HarnessInstallerApp(preselected_disk=args.disk)
        app.run()


if __name__ == "__main__":
    main()
