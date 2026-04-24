#!/usr/bin/env bash

set -euo pipefail

INTERNAL="eDP-1"
INTERNAL_MODE="2560x1440@165"
INTERNAL_SCALE="1.3"
INTERNAL_X="0"
INTERNAL_Y="0"
WALLPAPER_SYNC_SCRIPT="$HOME/.config/niri/scripts/wallpaper-sync.sh"
AWWW_SERVICE_SCRIPT="$HOME/.config/niri/scripts/awww-daemon-service.sh"
SYNC_LOCK_DIR="/tmp/niri-monitor-wallpaper-sync.lock"

have_external_output() {
    niri msg -j outputs | jq -e --arg internal "$INTERNAL" '
        map(select(.name != $internal and ((.is_connected // true) == true))) | length > 0
    ' >/dev/null
}

apply_state() {
    if have_external_output; then
        niri msg output "$INTERNAL" off >/dev/null 2>&1 || true
    else
        niri msg output "$INTERNAL" on >/dev/null 2>&1 || true
        niri msg output "$INTERNAL" mode "$INTERNAL_MODE" >/dev/null 2>&1 || true
        niri msg output "$INTERNAL" scale "$INTERNAL_SCALE" >/dev/null 2>&1 || true
        niri msg output "$INTERNAL" position set "$INTERNAL_X" "$INTERNAL_Y" >/dev/null 2>&1 || true
    fi
}

ensure_awww_running() {
    if awww query >/dev/null 2>&1; then
        return 0
    fi

    systemctl --user start --no-block awww-daemon.service >/dev/null 2>&1 || true
    sleep 0.8

    if awww query >/dev/null 2>&1; then
        return 0
    fi

    if [[ -x "$AWWW_SERVICE_SCRIPT" ]]; then
        "$AWWW_SERVICE_SCRIPT" >/dev/null 2>&1 &
        disown || true
        sleep 0.8
    fi

    awww query >/dev/null 2>&1
}

sync_wallpaper_after_output_change() {
    (
        if ! mkdir "$SYNC_LOCK_DIR" 2>/dev/null; then
            exit 0
        fi
        trap 'rmdir "$SYNC_LOCK_DIR" >/dev/null 2>&1 || true' EXIT

        sleep 0.5
        if ensure_awww_running && [[ -x "$WALLPAPER_SYNC_SCRIPT" ]]; then
            "$WALLPAPER_SYNC_SCRIPT" refresh >/dev/null 2>&1 || true
        fi
    ) &
}

apply_state
sync_wallpaper_after_output_change

niri msg event-stream | while read -r line; do
    case "$line" in
        *Output*|*output*)
            apply_state
            sync_wallpaper_after_output_change
            ;;
    esac
done
