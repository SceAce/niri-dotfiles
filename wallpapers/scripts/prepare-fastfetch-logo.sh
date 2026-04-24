#!/usr/bin/env bash
set -euo pipefail

source_root="/home/source/Pictures/Wallpapers"
out_dir="/home/source/Pictures/Wallpapers/desktop"
source_file="/tmp/fastfetch-logo-source.txt"

mkdir -p "$out_dir"

build_one() {
  local src="$1"
  local meta key out tmp_out
  meta=$(stat -c '%Y:%s' "$src" 2>/dev/null || echo '0:0')
  key=$(printf '%s|%s\n' "$src" "$meta" | sha1sum | awk '{print $1}')
  out="$out_dir/$key.png"

  if [[ -s "$out" ]]; then
    printf '%s\n' "$out"
    return 0
  fi

  tmp_out=$(mktemp "$out_dir/.build.XXXXXX.png")
  if command -v magick >/dev/null 2>&1; then
    magick "$src" -auto-orient -colorspace sRGB -strip -resize '1280x720>' PNG32:"$tmp_out"
  elif command -v convert >/dev/null 2>&1; then
    convert "$src" -auto-orient -colorspace sRGB -strip -resize '1280x720>' PNG32:"$tmp_out"
  else
    cp -f -- "$src" "$tmp_out"
  fi
  mv -f "$tmp_out" "$out"
  printf '%s\n' "$out"
}

# Pick one source image.
pick_src="$({
  find "$source_root" \
    -type d -name 'Dynamic-Wallpapers' -prune -o \
    -type d -name 'desktop' -prune -o \
    -type d -name 'scripts' -prune -o \
    -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    -size +0c \
    -print | shuf -n 1
} || true)"

if [[ -z "$pick_src" || ! -f "$pick_src" ]]; then
  exit 1
fi

printf '%s\n' "$pick_src" > "$source_file"

# Fast path: return cached converted image immediately.
meta=$(stat -c '%Y:%s' "$pick_src" 2>/dev/null || echo '0:0')
key=$(printf '%s|%s\n' "$pick_src" "$meta" | sha1sum | awk '{print $1}')
out_file="$out_dir/$key.png"
if [[ -s "$out_file" ]]; then
  printf '%s\n' "$out_file"
else
  # Fallback to any existing converted image for instant startup.
  fallback=$(find "$out_dir" -maxdepth 1 -type f -name '*.png' -size +0c 2>/dev/null | shuf -n 1 || true)
  if [[ -n "$fallback" ]]; then
    printf '%s\n' "$fallback"
  else
    # First run with empty desktop pool.
    build_one "$pick_src"
    exit 0
  fi
fi

# Background maintenance: convert one uncached image each run.
uncached_src="$({
  find "$source_root" \
    -type d -name 'Dynamic-Wallpapers' -prune -o \
    -type d -name 'desktop' -prune -o \
    -type d -name 'scripts' -prune -o \
    -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    -size +0c \
    -print | shuf -n 1
} || true)"

if [[ -n "$uncached_src" && -f "$uncached_src" ]]; then
  u_meta=$(stat -c '%Y:%s' "$uncached_src" 2>/dev/null || echo '0:0')
  u_key=$(printf '%s|%s\n' "$uncached_src" "$u_meta" | sha1sum | awk '{print $1}')
  u_out="$out_dir/$u_key.png"
  if [[ ! -s "$u_out" ]]; then
    lock_dir="$out_dir/.lock-$u_key"
    if mkdir "$lock_dir" 2>/dev/null; then
      (
        build_one "$uncached_src" >/dev/null 2>&1 || true
        rmdir "$lock_dir" >/dev/null 2>&1 || true
      ) >/dev/null 2>&1 &
    fi
  fi
fi

# Cleanup stale temp builds if any.
find "$out_dir" -maxdepth 1 -type f -name '.build.*.png' -delete 2>/dev/null || true
