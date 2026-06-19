# Auto-start Hyprland on tty1 login
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    # Brief info before Hyprland takes the screen
    cat /usr/local/share/harness/ascii-logo.txt 2>/dev/null || true
    printf '\e[1;36mHarnessOS Live\e[0m — AI-powered Arch Linux\n\n'
    printf '\e[1;33mInternet:\e[0m  Ethernet auto-connects. WiFi → run \e[1mnmtui\e[0m first.\n'
    printf '           After connecting: \e[1msystemctl restart harness-online-setup\e[0m\n\n'
    printf '\e[1;32mHyprland keybinds:\e[0m  SUPER+Return=terminal  SUPER+R=launcher  SUPER+C=claude\n\n'
    printf 'Starting Hyprland...\n'
    sleep 2
    exec Hyprland
fi
