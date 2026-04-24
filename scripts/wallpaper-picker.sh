#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
MODE="${1:-}"
SELECTED_ARG="${2:-}"

have() {
    command -v "$1" >/dev/null 2>&1
}

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    have notify-send && notify-send "niri" "壁纸目录不存在: $WALLPAPER_DIR"
    exit 1
fi

if ! have rofi; then
    have notify-send && notify-send "niri" "rofi 未安装，无法打开壁纸选择器"
    exit 1
fi

if [[ "$MODE" != "--rofi-mode" ]]; then
    if [[ -n "${1:-}" && "${1:-}" != "--rofi-mode" ]]; then
        WALLPAPER_DIR="$1"
    fi
    export WALLPAPER_DIR
    exec rofi -show wallpaper \
        -modi "wallpaper:$0 --rofi-mode" \
        -show-icons \
        -matching fuzzy \
        -theme-str 'window { width: 92%; }' \
        -theme-str 'listview { columns: 6; lines: 3; layout: vertical; cycle: true; spacing: 14px; }' \
        -theme-str 'element { orientation: vertical; children: [ element-icon, element-text ]; }' \
        -theme-str 'element-icon { size: 180px; border-radius: 10px; }' \
        -theme-str 'element-text { enabled: false; }' \
        -p "Wallpaper"
fi

if [[ "${ROFI_RETV:-0}" -eq 0 ]]; then
    mapfile -t wallpapers < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
            | sort
    )

    if [[ "${#wallpapers[@]}" -eq 0 ]]; then
        have notify-send && notify-send "niri" "壁纸目录为空: $WALLPAPER_DIR"
        exit 1
    fi

    for wp in "${wallpapers[@]}"; do
        name="$(basename "$wp")"
        # rofi 脚本模式行格式：text\0icon\x1f/path/to/image
        printf '%s\0icon\x1f%s\0info\x1f%s\n' "$name" "$wp" "$wp"
    done
    exit 0
fi

selection="${ROFI_INFO:-$SELECTED_ARG}"

if [[ -z "$selection" ]]; then
    exit 0
fi

if [[ -f "$selection" ]]; then
    exec "$HOME/.config/niri/scripts/set-wallpaper.sh" "$selection"
fi

# 兼容旧版 rofi 只回传显示文本（文件名）
candidate="$WALLPAPER_DIR/$selection"
if [[ -f "$candidate" ]]; then
    exec "$HOME/.config/niri/scripts/set-wallpaper.sh" "$candidate"
fi

exit 0
