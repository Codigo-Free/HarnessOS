# Auto-start Hyprland on tty1 login
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec Hyprland
fi
