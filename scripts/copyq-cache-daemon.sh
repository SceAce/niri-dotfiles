#!/usr/bin/env bash

set -euo pipefail

REFRESH_INTERVAL=4
MAX_ITEMS=28

"$HOME/.config/niri/scripts/copyq-cache-refresh.sh" "$MAX_ITEMS" || true

while true; do
    sleep "$REFRESH_INTERVAL"
    "$HOME/.config/niri/scripts/copyq-cache-refresh.sh" "$MAX_ITEMS" || true
done
