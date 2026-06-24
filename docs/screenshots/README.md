# Screenshots

This directory holds screenshots for the HarnessOS README and documentation.

## Required screenshots

| File | What to capture |
|------|----------------|
| `desktop.png` | Clean desktop — Waybar visible at top, wallpaper with logo, no windows open. Take from workspace 1. |
| `harness-ai.png` | `harness ai` session in Kitty. Ask "why might Docker fail to start?" and capture the response with the command suggestion dialog showing. |
| `installer.png` | TUI installer at the Progress screen — showing the installation log and progress bar mid-install. |
| `tui-tools.png` | Split terminal with lazygit on the left (showing a repo with commits) and k9s or lazydocker on the right. |
| `harness-doctor.png` | `harness doctor` output showing all green checks. |

## How to capture screenshots

Boot from the HarnessOS USB (or installed system) and run:

```bash
# Single screenshot (area select)
grimblast save area ~/Desktop/screenshot.png

# Full screen
grimblast save screen ~/Desktop/desktop.png

# Specific window
grimblast save active ~/Desktop/window.png
```

For screen recording (to create a GIF):

```bash
# Record to MP4
wf-recorder -f ~/Desktop/demo.mp4

# Convert to GIF (requires ffmpeg + gifsicle)
ffmpeg -i demo.mp4 -vf "fps=15,scale=1280:-1" -loop 0 demo.gif
gifsicle --optimize=3 --lossy=80 demo.gif -o demo-optimized.gif
```

## Recommended setup for clean screenshots

1. Open Kitty fullscreen (`Super+F`) for terminal screenshots
2. Use Tokyo Night theme (already configured — no changes needed)
3. Capture at 1920x1080 or 2560x1440
4. Keep Waybar visible (shows the full HarnessOS desktop identity)

## GIF for README hero (optional but high impact)

A 10-15 second GIF showing:
1. Boot → Hyprland desktop (2s)
2. `Super+A` → `harness ai` opens (1s)
3. Type a question → AI responds with system context (5s)
4. Command suggested and approved (3s)

Upload GIF to `docs/screenshots/demo.gif` and update the README hero section.
