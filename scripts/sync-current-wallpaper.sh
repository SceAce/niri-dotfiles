#!/usr/bin/env bash

set -euo pipefail

QUIET=0
if [[ "${1:-}" == "--quiet" ]]; then
    QUIET=1
fi

have() {
    command -v "$1" >/dev/null 2>&1
}

notify_msg() {
    if [[ "$QUIET" -eq 0 ]] && have notify-send; then
        notify-send "niri" "$1"
    fi
}

extract_wallpaper_from_awww() {
    local line
    awww query 2>/dev/null | while IFS= read -r line; do
        case "$line" in
            *"currently displaying: image: "*)
                printf '%s\n' "${line##*currently displaying: image: }"
                break
                ;;
        esac
    done
}

main() {
    local wallpaper=""

    if [[ -n "${1:-}" && "${1:-}" != "--quiet" ]]; then
        wallpaper="$1"
    elif [[ -n "${WALLPAPER_PATH:-}" ]]; then
        wallpaper="${WALLPAPER_PATH}"
    else
        wallpaper="$(extract_wallpaper_from_awww)"
    fi

    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        notify_msg "未读取到当前壁纸路径，无法同步"
        exit 1
    fi

    "$HOME/.config/niri/scripts/wallpaper-sync.sh" prepare-overview "$wallpaper"
    notify_msg "已同步当前壁纸到 Workspace overview 背景"
}

main "${1:-}"
