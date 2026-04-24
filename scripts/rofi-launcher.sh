#!/usr/bin/env bash

set -euo pipefail

launcher="$HOME/.config/rofi/launchers/type-6/launcher.sh"

pkill -x rofi >/dev/null 2>&1 || true

if [[ -x "$launcher" ]]; then
    exec "$launcher"
elif command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun -modi drun,run,filebrowser,window
else
    notify-send "niri" "rofi 不在 PATH 中"
    exit 1
fi
