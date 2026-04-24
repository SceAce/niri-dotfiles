#!/usr/bin/env bash

set -euo pipefail

if ! command -v copyq >/dev/null 2>&1; then
    notify-send "niri" "copyq 未安装或不在 PATH 中"
    exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
    notify-send "niri" "rofi 不在 PATH 中"
    exit 1
fi

ROFI_CONFIG="$HOME/.config/rofi/config-clipboard-modern.rasi"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/niri"
CACHE_FILE="$CACHE_DIR/copyq-menu-cache.tsv"
META_FILE="$CACHE_DIR/copyq-menu-cache.meta"
MAX_ITEMS=28
STALE_AFTER=12

mkdir -p "$CACHE_DIR"

if [[ ! -s "$CACHE_FILE" ]]; then
    "$HOME/.config/niri/scripts/copyq-cache-refresh.sh" "$MAX_ITEMS" || true
fi

if [[ -f "$META_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$META_FILE"
else
    item_count=0
    limit=0
    updated=0
fi

now="$(date +%s)"
if (( now - ${updated:-0} > STALE_AFTER )); then
    nohup "$HOME/.config/niri/scripts/copyq-cache-refresh.sh" "$MAX_ITEMS" >/dev/null 2>&1 &
fi

if [[ -s "$CACHE_FILE" ]]; then
    entries="$(cat "$CACHE_FILE")"
else
    notify-send "niri" "剪贴板缓存为空，稍后再试"
    exit 1
fi

selection="$(
    printf '%s\n' "$entries" | rofi -dmenu -i -markup-rows -no-custom -p "Clipboard" -mesg "CopyQ history • showing ${limit:-0}/${item_count:-0}" -config "$ROFI_CONFIG"
)"

[[ -n "${selection}" ]] || exit 0

index="$(printf '%s' "$selection" | cut -f1)"
[[ -n "$index" ]] || exit 0

copyq select "$index"
