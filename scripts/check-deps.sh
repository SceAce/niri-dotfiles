#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/lib/niri-config.sh"

failures=0

check_cmd() {
    local name="$1"
    local required="${2:-1}"

    if command -v "$name" >/dev/null 2>&1; then
        printf '[ok]   command: %s\n' "$name"
    else
        if [[ "$required" -eq 1 ]]; then
            printf '[miss] command: %s\n' "$name"
            failures=1
        else
            printf '[opt]  command: %s\n' "$name"
        fi
    fi
}

check_path() {
    local label="$1"
    local path="$2"
    local required="${3:-0}"

    if [[ -e "$path" ]]; then
        printf '[ok]   %s: %s\n' "$label" "$path"
    else
        if [[ "$required" -eq 1 ]]; then
            printf '[miss] %s: %s\n' "$label" "$path"
            failures=1
        else
            printf '[opt]  %s: %s\n' "$label" "$path"
        fi
    fi
}

echo "== Core commands =="
for cmd in niri jq grim slurp satty wl-copy hyprlock swayidle rofi ghostty thunar copyq mako fcitx5 brightnessctl notify-send dbus-update-activation-environment gdbus xhost; do
    check_cmd "$cmd" 1
done

echo
echo "== Extra commands =="
for cmd in awww awww-daemon qs mouse-actions hyprpicker swayosd-client swayosd-server playerctl; do
    check_cmd "$cmd" 0
done

echo
echo "== Runtime paths =="
check_path "wallpaper dir" "$NIRI_WALLPAPER_DIR" 0
check_path "toggle-wlsunset" "$NIRI_TOGGLE_WLSUNSET" 0
check_path "hyprlock colors" "$HOME/.cache/matugen/hypr/colors.conf" 0
check_path "rofi config dir" "$HOME/.config/rofi" 0
check_path "tray QQ icon" "$NIRI_TRAY_QQ_ICON" 0
check_path "tray WeChat icon" "$NIRI_TRAY_WECHAT_ICON" 0
check_path "awww service" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/awww-daemon.service" 0
check_path "restore service" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/niri-wallpaper-restore.service" 0

echo
echo "== Notes =="
echo "[opt] awww / qs / mouse-actions are optional for basic niri startup, but some desktop features depend on them."
echo "[opt] if systemd --user is unavailable in the current shell, service checks may still pass after login."

exit "$failures"
