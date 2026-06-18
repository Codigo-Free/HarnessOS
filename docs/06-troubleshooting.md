# Troubleshooting

## Boot issues

### "Timed out waiting for device /dev/gpt-auto-root"
The `archiso` mkinitcpio hook is missing from the initramfs. Ensure `mkinitcpio-archiso` is in `packages.x86_64` and that `customize_airootfs.sh` calls `mkinitcpio -p linux-zen` after the preset files are applied.

### "Failed to mount '' on real root"
The archiso hook ran but couldn't find the USB by label. Causes:
- USB storage modules not loaded before the hook runs — add `MODULES=(usb_storage squashfs)` to `mkinitcpio.conf.d/archiso.conf`
- Label mismatch between ISO and boot entry (verify with `blkid`)

### Black screen after Hyprland starts
Hyprland is running but no windows are visible. Press `SUPER + Q` to open a terminal. If SUPER doesn't work in a VM, press Ctrl+Alt first to capture keyboard focus.

### Hyprland refuses to start: "launched with superuser privileges"
Hyprland cannot run as root. The live user must be `harness` (non-root). Autologin must target `harness`, not `root`.

## Login issues

### "Login incorrect" on root login
The root account has a locked password by default in Arch. Run `passwd -d root` in `customize_airootfs.sh` to unlock it for the live environment, or ensure autologin is configured for the `harness` user.

## AI tools

### `claude: command not found`
`harness-online-setup.service` installs Claude CLI on first boot with internet. Check its status:
```bash
systemctl status harness-online-setup.service
journalctl -u harness-online-setup.service
```
Install manually:
```bash
npm install -g @anthropic-ai/claude-code
```

### `code: command not found`
VS Code (`code` package, Code-OSS) must be in `packages.x86_64`. It is not installed by default on Arch.

### Ollama not responding
```bash
systemctl status ollama.service
systemctl start ollama.service
```

## Build issues

### "Failed to install packages to new root"
A package in `packages.x86_64` doesn't exist or has a dependency conflict. Check the full error output for the specific package name. Common causes:
- Package renamed in Arch repos (e.g., `gh` → `github-cli`)
- Package moved from AUR to official repos or vice versa
- Typo in package name

### mkinitcpio warnings about missing hooks
The `archiso`, `archiso_loop_mnt` hooks require `mkinitcpio-archiso` package to be installed in the airootfs. The standard `archiso` package (the build tool) does not install hook files into the system.

### Build hangs at SquashFS compression
Normal behavior — XZ compression of 2–3 GB of packages on 4 cores takes 20–40 minutes. Do not interrupt.

## Networking

### Wi-Fi not connecting in live environment
```bash
nmtui          # NetworkManager TUI — connect to Wi-Fi
nmcli device   # List network devices
```

### `harness-online-setup` times out waiting for internet
The service waits 30 seconds for `ping archlinux.org`. Connect to the network first, then restart the service:
```bash
nmtui
systemctl restart harness-online-setup.service
```
