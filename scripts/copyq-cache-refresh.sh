#!/usr/bin/env bash

set -euo pipefail

if ! command -v copyq >/dev/null 2>&1; then
    exit 0
fi

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/niri"
CACHE_FILE="$CACHE_DIR/copyq-menu-cache.tsv"
META_FILE="$CACHE_DIR/copyq-menu-cache.meta"
MAX_ITEMS="${1:-28}"

mkdir -p "$CACHE_DIR"

if ! copyq size >/dev/null 2>&1; then
    copyq >/dev/null 2>&1 &
    sleep 0.5
fi

if ! size="$(copyq size 2>/dev/null)"; then
    exit 0
fi

limit="$size"
if (( limit > MAX_ITEMS )); then
    limit="$MAX_ITEMS"
fi

tmp_cache="$(mktemp "$CACHE_DIR/copyq-cache.XXXXXX")"
tmp_meta="$(mktemp "$CACHE_DIR/copyq-cache-meta.XXXXXX")"

escape_markup() {
    local text="$1"
    text="${text//&/\&amp;}"
    text="${text//</\&lt;}"
    text="${text//>/\&gt;}"
    printf '%s' "$text"
}

for ((i = 0; i < limit; i++)); do
    item="$(copyq read "$i" 2>/dev/null || true)"
    item="${item//$'\n'/ }"
    item="${item//$'\r'/ }"
    while [[ "$item" == *"  "* ]]; do
        item="${item//  / }"
    done
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    short="${item:0:120}"

    if [[ -z "$short" ]]; then
        short="<binary or empty item>"
    fi

    if [[ ${#item} -gt 120 ]]; then
        short="${short}..."
    fi

    short="$(escape_markup "$short")"
    printf '%s\t<span alpha="96%%">%s</span>\n' "$i" "$short" >>"$tmp_cache"
done

printf 'item_count=%s\n' "$size" >"$tmp_meta"
printf 'limit=%s\n' "$limit" >>"$tmp_meta"
printf 'updated=%s\n' "$(date +%s)" >>"$tmp_meta"

mv "$tmp_cache" "$CACHE_FILE"
mv "$tmp_meta" "$META_FILE"
