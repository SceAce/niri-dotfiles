#!/usr/bin/env bash

set -euo pipefail

config_path="$HOME/.config/niri/mouse-actions.json"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mouse-actions"
log_path="$state_dir/mouse-actions.log"

mkdir -p "$state_dir"

mouse_actions_bin=""
if command -v mouse-actions >/dev/null 2>&1; then
    mouse_actions_bin="$(command -v mouse-actions)"
elif [[ -x "$HOME/.cargo/bin/mouse-actions" ]]; then
    mouse_actions_bin="$HOME/.cargo/bin/mouse-actions"
elif [[ -x "$HOME/.local/bin/mouse-actions" ]]; then
    mouse_actions_bin="$HOME/.local/bin/mouse-actions"
else
    exit 0
fi

if pgrep -u "$USER" -f "mouse-actions.*$config_path" >/dev/null 2>&1; then
    exit 0
fi

if ! id -nG "$USER" | grep -Eq '(^| )(input|plugdev)( |$)'; then
    command -v notify-send >/dev/null 2>&1 && notify-send "niri" "mouse-actions 需要 input/plugdev 设备权限；当前手势不会生效。"
fi

if [[ -e /dev/uinput ]] && [[ ! -r /dev/uinput || ! -w /dev/uinput ]]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "niri" "mouse-actions 无法访问 /dev/uinput；当前手势不会生效。"
fi

nohup "$mouse_actions_bin" --no-listen --config-path "$config_path" start >>"$log_path" 2>&1 &
