# Live Environment

The HarnessOS ISO boots directly into a fully functional live environment without touching your disk. All changes are lost on reboot.

## Booting

1. Flash the ISO to a USB drive (8 GB minimum, 16 GB recommended):
   ```bash
   sudo dd if=harnessOS-YYYY.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync && sync
   ```
2. Boot the target machine from USB. The BIOS/UEFI must be in **UEFI mode** (not Legacy/CSM). HarnessOS is UEFI-only.
3. The system auto-logs in as user `harness` and launches **Hyprland** automatically.

## Default credentials

| Field | Value |
|-------|-------|
| Live user | `harness` |
| Password | *(none — passwordless login)* |
| sudo | Passwordless for `harness` |

## Desktop keybindings

| Shortcut | Action |
|----------|--------|
| `SUPER + Return` or `SUPER + Q` | Open terminal (Kitty) |
| `SUPER + B` | Open Firefox |
| `SUPER + E` | Open VS Code |
| `SUPER + R` | App launcher (Wofi) |
| `SUPER + C` | Claude AI in terminal |
| `SUPER + O` | Ollama (llama3.2) in terminal |
| `SUPER + W` | Close focused window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + Space` | Toggle floating |
| `SUPER + 1–4` | Switch to workspace 1–4 |
| `SUPER + SHIFT + 1–4` | Move window to workspace |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + arrow keys` | Move focus |
| `SUPER + mouse drag` | Move window |
| `SUPER + right-click drag` | Resize window |
| `Print` | Screenshot (select area) |
| `SUPER + SHIFT + E` | Exit Hyprland |

## Top bar (Waybar)

The horizontal bar at the top contains:

**Left side:**
- **⬡ HarnessOS** — click to open app launcher (Wofi)
- **Workspace indicators 1–4** — always visible, click to switch (or `SUPER+1–4`)

**Right side:**
- **Firefox** icon — open browser
- **Terminal** icon — open Kitty
- **VS Code** icon — open editor
- **Claude** icon — open Claude CLI in terminal
- **Power button** — shutdown / reboot / suspend menu

## Online setup (first boot with internet)

On first boot, `harness-online-setup.service` runs automatically when network is available. It installs:

```
@anthropic-ai/claude-code   # claude command
pnpm                        # fast npm alternative
typescript, ts-node, tsx    # TypeScript tools
github/gh-copilot extension # Copilot CLI
```

Check status:
```bash
systemctl status harness-online-setup.service
journalctl -u harness-online-setup.service
```

If it didn't run (no internet at first boot):
```bash
# 1. Connect to WiFi
nmtui

# 2. Restart the setup service
systemctl restart harness-online-setup.service

# Or install manually:
npm install -g @anthropic-ai/claude-code pnpm typescript ts-node tsx
```

## TUI tools

All lazy TUI tools are pre-installed and aliased in the shell:

| Alias | Tool | What it does |
|-------|------|-------------|
| `lg` | lazygit | Git staging, commits, branches, diffs |
| `lzd` | lazydocker | Docker containers, images, logs |
| `y` | yazi | File manager — exits and `cd`s to last directory |
| `z <dir>` | zoxide | Smart `cd` — learns your most-used dirs |
| `top` | bottom (`btm`) | Process / resource monitor |
| `logs` | lnav | Log file navigator with filtering |
| `k` | k9s | Kubernetes cluster TUI |

Other shell aliases:
```bash
ls   → eza --icons        # Better ls with icons
ll   → eza -la --icons    # Long list with git status
cat  → bat --style=plain  # Syntax-highlighted cat
vim  → nvim               # Neovim
d    → docker
dc   → docker compose
dps  → docker ps (formatted)
wifi → nmtui              # Connect to WiFi
```

## Launching the installer

To install HarnessOS permanently on a disk:
```bash
harness-install
```

This opens the TUI installer. **Nothing is written to disk until you confirm on the final screen.**
