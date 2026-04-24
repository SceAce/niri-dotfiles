#!/usr/bin/env bash

set -euo pipefail

theme="${HOME}/.config/rofi/powermenu/type-6/style-1.rasi"
host="$(hostname)"
uptime_str="$(uptime -p | sed 's/^up //')"

rofi_cmd() {
    rofi -dmenu \
        -p " ${USER}@${host}" \
        -mesg "Uptime: ${uptime_str}" \
        -theme "$theme"
}

confirm_cmd() {
    rofi \
        -theme "$theme" \
        -theme-str 'window { location: center; anchor: center; fullscreen: false; width: 360px; }' \
        -theme-str 'mainbox { orientation: vertical; children: [ "message", "listview" ]; }' \
        -theme-str 'listview { columns: 2; lines: 1; }' \
        -theme-str 'element-text { horizontal-align: 0.5; }' \
        -theme-str 'textbox { horizontal-align: 0.5; }' \
        -dmenu \
        -p "确认" \
        -mesg "确定执行吗？"
}

confirm_or_exit() {
    local choice
    choice="$(printf 'Yes\nNo\n' | confirm_cmd)"
    [[ "$choice" == "Yes" ]]
}

action="$(printf 'Lock\nSuspend\nLogout\nReboot\nShutdown\n' | rofi_cmd)"

case "$action" in
    Lock)
        exec "$HOME/.config/niri/scripts/lock-screen.sh"
        ;;
    Suspend)
        confirm_or_exit || exit 0
        "$HOME/.config/niri/scripts/lock-screen.sh"
        exec systemctl suspend
        ;;
    Logout)
        confirm_or_exit || exit 0
        exec niri msg action quit
        ;;
    Reboot)
        confirm_or_exit || exit 0
        exec systemctl reboot
        ;;
    Shutdown)
        confirm_or_exit || exit 0
        exec systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
