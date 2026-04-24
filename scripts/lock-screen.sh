#!/usr/bin/env bash

set -euo pipefail

HYPRLOCK_PRIMARY="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"
HYPRLOCK_FALLBACK="${XDG_CONFIG_HOME:-$HOME/.config}/niri/hyprlock.conf"

if ! command -v hyprlock >/dev/null 2>&1; then
    notify-send "Lock Screen" "hyprlock 未安装或不在 PATH 中"
    exit 1
fi

CONFIG_FILE="$HYPRLOCK_PRIMARY"
if [[ ! -f "$CONFIG_FILE" && -f "$HYPRLOCK_FALLBACK" ]]; then
    CONFIG_FILE="$HYPRLOCK_FALLBACK"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    notify-send "Lock Screen" "未找到 hyprlock 配置: $HYPRLOCK_PRIMARY 或 $HYPRLOCK_FALLBACK"
    exit 1
fi

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

cmd=(hyprlock --config "$CONFIG_FILE")

if [[ "${1:-}" == "--daemonize" ]]; then
    "${cmd[@]}" >/dev/null 2>&1 &
    disown || true
    sleep 0.2
    exit 0
fi

exec "${cmd[@]}"
