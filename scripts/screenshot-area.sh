#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/screenshot-common.sh"

need_cmd grim
need_cmd slurp
need_cmd satty
need_cmd wl-copy

ensure_tmp_dir

geometry="$(slurp -d 2>/dev/null || true)"
if [ -z "$geometry" ]; then
    exit 0
fi

raw_file="$(mktemp --tmpdir="$SCREENSHOT_TMP_DIR" niri-area-XXXXXX.png)"
out_file="$SCREENSHOT_TMP_DIR/$(timestamp_png)"

cleanup() {
    rm -f "$raw_file"
}
trap cleanup EXIT

grim -g "$geometry" "$raw_file"

satty \
    --filename "$raw_file" \
    --resize 1200x900 \
    --fullscreen current-screen \
    --floating-hack \
    --initial-tool crop \
    --copy-command wl-copy \
    --output-filename "$out_file" \
    --actions-on-enter save-to-clipboard,save-to-file,exit \
    --actions-on-right-click save-to-clipboard \
    --actions-on-escape exit

if [ -s "$out_file" ]; then
    play_shutter
    notify_saved "$out_file"
fi
