#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
case "$dir" in
  left|right) ;;
  *)
    echo "usage: $0 <left|right>" >&2
    exit 2
    ;;
esac

log_file="${XDG_CACHE_HOME:-$HOME/.cache}/niri-page-columns.log"
mkdir -p "$(dirname "$log_file")"

wins_json="$(niri msg -j windows)"
focused_json="$(niri msg -j focused-window)"
output_json="$(niri msg -j focused-output)"

target_id="$(
  jq -rn \
    --arg dir "$dir" \
    --argjson wins "$wins_json" \
    --argjson focused "$focused_json" \
    --argjson output "$output_json" '
      def xof:
        .layout.pos_in_scrolling_layout[0]
        // .layout.pos_in_scrolling_layout.x
        // .layout.tile_pos_in_workspace_view[0]
        // .layout.tile_pos_in_workspace_view.x
        // empty;

      def yof:
        .layout.pos_in_scrolling_layout[1]
        // .layout.pos_in_scrolling_layout.y
        // .layout.tile_pos_in_workspace_view[1]
        // .layout.tile_pos_in_workspace_view.y
        // 0;

      def workspace_id_of:
        .workspace_id;

      def output_width_of:
        .logical.width;

      def tile_width_of:
        .layout.tile_size[0]
        // .layout.tile_size.width
        // .layout.window_size[0]
        // .layout.window_size.width;

      def colkey: ((.x * 100) | round);

      $focused.workspace_id as $ws
      | ($focused | xof) as $focused_x
      | ($focused | tile_width_of) as $tile_w
      | ($output | output_width_of) as $width
      | if ($focused_x == null or $width == null or $ws == null or $tile_w == null) then
          empty
        else
          (($width / $tile_w) | floor) as $visible_cols_raw
          | (if $visible_cols_raw < 1 then 1 else $visible_cols_raw end) as $visible_cols
          | $wins
          | map(select(.workspace_id == $ws and (.is_floating | not) and (xof != null)) | {
              id,
              x: xof,
              y: yof
            })
          | sort_by(.x, .y)
          | group_by(colkey)
          | map(sort_by(.y)[0])
          | to_entries
          | (map(select(.value.x == $focused_x)) | first.key) as $focused_idx
          | if $focused_idx == null then
              empty
            else
              (($focused_idx / $visible_cols) | floor | . * $visible_cols) as $page_start
              | (if $dir == "right"
                 then ($page_start + (2 * $visible_cols) - 1)
                 else ($page_start - $visible_cols)
                 end) as $target_idx
              | if $target_idx < 0 then
                  empty
                else
                  .[$target_idx].value.id
                end
            end
        end
    ' 2>>"$log_file"
)"

{
  echo "[$(date '+%F %T')] dir=$dir"
  echo "focused=$(jq -c '.' <<<"$focused_json" 2>/dev/null || printf '%s' "$focused_json")"
  echo "output=$(jq -c '.' <<<"$output_json" 2>/dev/null || printf '%s' "$output_json")"
  echo "target_id=${target_id:-<none>}"
} >>"$log_file"

if [[ -n "$target_id" ]]; then
  exec niri msg action focus-window --id "$target_id"
fi
