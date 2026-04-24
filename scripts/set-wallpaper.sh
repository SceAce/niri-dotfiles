#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
    echo "Usage: $0 <wallpaper-path>" >&2
    exit 1
fi

wallpaper="$1"
if [[ ! -f "$wallpaper" ]]; then
    echo "Wallpaper not found: $wallpaper" >&2
    exit 1
fi

exec "$HOME/.config/niri/scripts/wallpaper-sync.sh" set "$wallpaper"
