#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/screenshot-common.sh"

need_cmd grim
need_cmd niri
need_cmd jq

ensure_tmp_dir

output_name="$(niri msg -j focused-output | jq -r '.name // empty')"
if [ -z "$output_name" ]; then
    notify-send "niri" "截图失败：无法读取当前输出"
    exit 1
fi

out_file="$SCREENSHOT_TMP_DIR/$(timestamp_png)"
grim -o "$output_name" "$out_file"

if [ -s "$out_file" ]; then
    play_shutter
    notify_saved "$out_file"
fi
