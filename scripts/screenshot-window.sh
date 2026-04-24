#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/screenshot-common.sh"

need_cmd grim
need_cmd satty
need_cmd wl-copy
need_cmd jq
need_cmd niri

ensure_tmp_dir

window_json="$(niri msg -j focused-window 2>/dev/null || true)"
if [ -z "$window_json" ]; then
    notify-send "niri" "窗口截图失败：未找到当前聚焦窗口"
    exit 1
fi

window_id="$(jq -r '.id // empty' <<<"$window_json")"

if [ -z "$window_id" ]; then
    notify-send "niri" "窗口截图失败：无法读取窗口 ID"
    exit 1
fi

raw_file="$(mktemp --tmpdir="$SCREENSHOT_TMP_DIR" niri-window-XXXXXX.png)"
out_file="$SCREENSHOT_TMP_DIR/$(timestamp_png)"

cleanup() {
    rm -f "$raw_file"
}
trap cleanup EXIT

grim -T "$window_id" "$raw_file"

satty \
    --filename "$raw_file" \
    --resize 1200x900 \
    --fullscreen current-screen \
    --floating-hack \
    --copy-command wl-copy \
    --output-filename "$out_file" \
    --actions-on-enter save-to-clipboard,save-to-file,exit \
    --actions-on-right-click save-to-clipboard \
    --actions-on-escape exit

if [ -s "$out_file" ]; then
    play_shutter
    notify_saved "$out_file"
fi
