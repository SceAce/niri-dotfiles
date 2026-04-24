#!/usr/bin/env bash

set -euo pipefail

NIRI_CONFIG_FILE="${NIRI_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/niri/scripts/niri-user-config.sh}"

if [[ -f "$NIRI_CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$NIRI_CONFIG_FILE"
fi

: "${NIRI_WALLPAPER_DIR:=$HOME/Pictures/Wallpapers}"
: "${NIRI_INTERNAL_OUTPUT:=eDP-1}"
: "${NIRI_INTERNAL_MODE:=2560x1440@165}"
: "${NIRI_INTERNAL_SCALE:=1.3}"
: "${NIRI_INTERNAL_X:=0}"
: "${NIRI_INTERNAL_Y:=0}"
: "${NIRI_ZEN_CANDIDATES:=$HOME/tools/zen/zen:$HOME/opt/zen/zen}"
: "${NIRI_TRAY_QQ_ICON:=$HOME/tools/LinuxQQ/qq.png}"
: "${NIRI_TRAY_WECHAT_ICON:=$HOME/tools/Wechat/wechat.png}"
: "${NIRI_TOGGLE_WLSUNSET:=$HOME/.local/bin/toggle-wlsunset}"
