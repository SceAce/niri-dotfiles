#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/lib/niri-config.sh"

if [[ -x "$NIRI_TOGGLE_WLSUNSET" ]]; then
    exec "$NIRI_TOGGLE_WLSUNSET"
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send "niri" "toggle-wlsunset 脚本不存在: $NIRI_TOGGLE_WLSUNSET"
fi

exit 1
