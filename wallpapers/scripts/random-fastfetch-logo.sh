#!/usr/bin/env bash
set -euo pipefail

root_dir="/home/source/Pictures/Wallpapers"

pick="$({
  find "$root_dir" \
    -type d -name 'Dynamic-Wallpapers' -prune -o \
    -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    -size +0c \
    -print0 | shuf -z -n 1 | tr -d '\0'
} || true)"

if [[ -n "$pick" ]]; then
  printf '%s\n' "$pick"
fi
