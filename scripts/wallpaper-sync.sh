#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/lib/niri-config.sh"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/niri"
STATE_FILE="$CACHE_DIR/current-wallpaper"
OVERVIEW_IMAGE="$CACHE_DIR/overview-wallpaper.png"
OVERVIEW_META="$CACHE_DIR/overview-wallpaper.meta"
OVERVIEW_POOL_DIR="$CACHE_DIR/overview-wallpapers"
CURRENT_LINK="${XDG_CACHE_HOME:-$HOME/.cache}/.current_wallpaper"
OVERVIEW_LOCK_DIR="$CACHE_DIR/overview.lock"
OVERVIEW_BATCH_LOCK_DIR="$CACHE_DIR/overview-batch.lock"
DEFAULT_DIR_CANDIDATES=(
    "$NIRI_WALLPAPER_DIR"
    "$HOME/Pictures/wallpapers"
)
WALLPAPER_TRANSITION_TYPE="${WALLPAPER_TRANSITION_TYPE:-fade}"
WALLPAPER_TRANSITION_TYPES="${WALLPAPER_TRANSITION_TYPES:-fade,center}"
WALLPAPER_TRANSITION_DURATION="${WALLPAPER_TRANSITION_DURATION:-0.9}"
WALLPAPER_TRANSITION_FPS="${WALLPAPER_TRANSITION_FPS:-120}"
WALLPAPER_TRANSITION_BEZIER="${WALLPAPER_TRANSITION_BEZIER:-.22,1,.36,1}"

mkdir -p "$CACHE_DIR" "$OVERVIEW_POOL_DIR"

have() {
    command -v "$1" >/dev/null 2>&1
}

warn_no_wallpaper() {
    if have notify-send; then
        notify-send "niri" "未找到可用壁纸，请检查 $NIRI_WALLPAPER_DIR"
    fi
}

resolve_wallpaper() {
    if [[ -n "${1:-}" ]]; then
        printf '%s\n' "$1"
    elif [[ -s "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    elif [[ -L "$CURRENT_LINK" ]]; then
        readlink -f "$CURRENT_LINK"
    else
        pick_random_from_dir
    fi
}

wallpaper_dir() {
    local dir

    for dir in "${DEFAULT_DIR_CANDIDATES[@]}"; do
        if [[ -d "$dir" ]]; then
            printf '%s\n' "$dir"
            return 0
        fi
    done

    return 1
}

pick_random_from_dir() {
    local dir
    dir="$(wallpaper_dir)" || return 0

    list_wallpapers "$dir" | shuf -n 1
}

write_state() {
    local wallpaper="$1"
    printf '%s\n' "$wallpaper" >"$STATE_FILE"
    ln -sfn "$wallpaper" "$CURRENT_LINK"
}

wallpaper_signature() {
    local wallpaper="$1"
    stat -Lc '%n|%Y|%s' "$wallpaper"
}

hash_text() {
    if have sha256sum; then
        sha256sum | awk '{print $1}'
    elif have shasum; then
        shasum -a 256 | awk '{print $1}'
    else
        cksum | awk '{print $1}'
    fi
}

list_wallpapers() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | sort
}

overview_cache_path() {
    local wallpaper="$1"
    local signature
    local key
    signature="$(wallpaper_signature "$wallpaper")"
    key="$(printf '%s' "$signature" | hash_text)"
    printf '%s/%s.png\n' "$OVERVIEW_POOL_DIR" "$key"
}

render_overview_to() {
    local wallpaper="$1"
    local target="$2"
    local tmp_image="$target.tmp"

    if have magick; then
        magick "$wallpaper" -resize 2560x1440^ -gravity center -extent 2560x1440 \
            -blur 0x18 -brightness-contrast -12x8 "$tmp_image"
    elif have convert; then
        convert "$wallpaper" -resize 2560x1440^ -gravity center -extent 2560x1440 \
            -blur 0x18 -brightness-contrast -12x8 "$tmp_image"
    else
        cp "$wallpaper" "$tmp_image"
    fi

    mv -f "$tmp_image" "$target"
}

ensure_overview_cached() {
    local wallpaper="$1"
    local cache_path
    cache_path="$(overview_cache_path "$wallpaper")"
    if [[ ! -s "$cache_path" ]]; then
        render_overview_to "$wallpaper" "$cache_path"
    fi
    printf '%s\n' "$cache_path"
}

activate_overview_for_wallpaper() {
    local wallpaper="$1"
    local cache_path
    local signature
    cache_path="$(ensure_overview_cached "$wallpaper")"
    ln -sfn "$cache_path" "$OVERVIEW_IMAGE"
    signature="$(wallpaper_signature "$wallpaper")"
    printf '%s\n' "$signature" >"$OVERVIEW_META"
    apply_overview_awww "$OVERVIEW_IMAGE"
}

apply_desktop_awww() {
    local wallpaper="$1"
    local transition_type="$WALLPAPER_TRANSITION_TYPE"
    local pool=()

    if have awww; then
        IFS=',' read -r -a pool <<<"$WALLPAPER_TRANSITION_TYPES"
        if [[ "${#pool[@]}" -gt 0 ]]; then
            transition_type="${pool[RANDOM % ${#pool[@]}]}"
        fi
        awww img \
            --transition-type "$transition_type" \
            --transition-duration "$WALLPAPER_TRANSITION_DURATION" \
            --transition-fps "$WALLPAPER_TRANSITION_FPS" \
            --transition-bezier "$WALLPAPER_TRANSITION_BEZIER" \
            "$wallpaper" || true
    fi
}

apply_overview_awww() {
    local overview_image="${1:-$OVERVIEW_IMAGE}"
    if have awww && [[ -f "$overview_image" ]]; then
        awww img -n overview --transition-type none --transition-step 255 --transition-fps 255 "$overview_image" || true
    fi
}

schedule_overview_update() {
    local wallpaper="$1"

    (
        if ! mkdir "$OVERVIEW_LOCK_DIR" 2>/dev/null; then
            exit 0
        fi
        trap 'rmdir "$OVERVIEW_LOCK_DIR" >/dev/null 2>&1 || true' EXIT

        activate_overview_for_wallpaper "$wallpaper"
    ) >/dev/null 2>&1 &
}

build_overview_cache_all() {
    local dir
    local wallpaper
    dir="$(wallpaper_dir)" || return 0
    while IFS= read -r wallpaper; do
        [[ -n "$wallpaper" ]] || continue
        ensure_overview_cached "$wallpaper" >/dev/null
    done < <(list_wallpapers "$dir")
}

schedule_overview_cache_build() {
    (
        if ! mkdir "$OVERVIEW_BATCH_LOCK_DIR" 2>/dev/null; then
            exit 0
        fi
        trap 'rmdir "$OVERVIEW_BATCH_LOCK_DIR" >/dev/null 2>&1 || true' EXIT
        build_overview_cache_all
    ) >/dev/null 2>&1 &
}

apply_wallpaper() {
    local wallpaper
    wallpaper="$(resolve_wallpaper "${1:-}")"
    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        warn_no_wallpaper
        exit 1
    fi
    write_state "$wallpaper"
    apply_desktop_awww "$wallpaper"
    schedule_overview_update "$wallpaper"
    schedule_overview_cache_build
}

random_wallpaper() {
    local wallpaper
    wallpaper="$(pick_random_from_dir)"
    [[ -n "$wallpaper" ]]
    apply_wallpaper "$wallpaper"
}

restore_wallpaper() {
    local wallpaper=""

    if [[ -s "$STATE_FILE" ]]; then
        wallpaper="$(resolve_wallpaper)"
    else
        wallpaper="$(pick_random_from_dir)"
    fi

    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        warn_no_wallpaper
        exit 0
    fi

    write_state "$wallpaper"
    apply_desktop_awww "$wallpaper"
    schedule_overview_update "$wallpaper"
    schedule_overview_cache_build
}

prepare_overview_wallpaper() {
    local wallpaper
    wallpaper="$(resolve_wallpaper "${1:-}")"
    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        warn_no_wallpaper
        exit 1
    fi

    write_state "$wallpaper"
    activate_overview_for_wallpaper "$wallpaper"
    schedule_overview_cache_build
}

case "${1:-restore}" in
    init|restore)
        restore_wallpaper
        ;;
    refresh)
        apply_wallpaper
        ;;
    prepare-overview)
        prepare_overview_wallpaper "${2:-}"
        ;;
    build-overview-cache)
        build_overview_cache_all
        ;;
    random)
        random_wallpaper
        ;;
    set)
        apply_wallpaper "${2:-}"
        ;;
    *)
        echo "Usage: $0 [restore|refresh|prepare-overview|build-overview-cache|random|set <path>]" >&2
        exit 1
        ;;
esac
