#!/usr/bin/env bash

set -euo pipefail

SCREENSHOT_TMP_DIR="${SCREENSHOT_TMP_DIR:-/tmp/niri-screenshots}"
SCREENSHOT_SOUND="${SCREENSHOT_SOUND:-/usr/share/sounds/freedesktop/stereo/camera-shutter.oga}"

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        notify-send "niri" "截图失败：缺少命令 $1"
        exit 1
    fi
}

ensure_tmp_dir() {
    mkdir -p "$SCREENSHOT_TMP_DIR"
}

timestamp_png() {
    date +'%Y-%m-%d %H-%M-%S.png'
}

play_shutter() {
    if command -v pw-play >/dev/null 2>&1 && [ -f "$SCREENSHOT_SOUND" ]; then
        pw-play "$SCREENSHOT_SOUND" >/dev/null 2>&1 &
    fi
}

notify_saved() {
    notify-send "niri" "截图已保存到 $1"
}
