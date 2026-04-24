#!/usr/bin/env bash

set -euo pipefail

QS_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/niri/quickshell/noctalia-shell"

have_qs() {
    command -v qs >/dev/null 2>&1
}

ensure_qs() {
    if ! have_qs; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "niri" "qs / Quickshell 未安装或不在 PATH 中"
        fi
        exit 1
    fi
}

ensure_config() {
    if [[ ! -f "$QS_CONFIG_PATH/shell.qml" ]]; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "niri" "Noctalia Shell 配置不存在: $QS_CONFIG_PATH"
        fi
        exit 1
    fi
}

start_shell() {
    ensure_qs
    ensure_config
    exec qs -p "$QS_CONFIG_PATH"
}

start_shell_bg() {
    ensure_qs
    ensure_config
    nohup qs -p "$QS_CONFIG_PATH" >/dev/null 2>&1 &
}

reload_shell() {
    ensure_qs
    ensure_config
    qs -p "$QS_CONFIG_PATH" kill >/dev/null 2>&1 || true
    start_shell_bg
}

toggle_shell() {
    ensure_qs
    ensure_config
    if qs -p "$QS_CONFIG_PATH" list >/dev/null 2>&1; then
        qs -p "$QS_CONFIG_PATH" kill >/dev/null 2>&1 || true
    else
        start_shell_bg
    fi
}

ipc_call() {
    ensure_qs
    ensure_config
    exec qs ipc --any-display -p "$QS_CONFIG_PATH" call "$@"
}

case "${1:-start}" in
    start)
        start_shell
        ;;
    start-bg)
        start_shell_bg
        ;;
    reload)
        reload_shell
        ;;
    toggle)
        toggle_shell
        ;;
    ipc)
        shift
        ipc_call "$@"
        ;;
    *)
        echo "Usage: $0 [start|start-bg|reload|toggle|ipc <handler> <function> [args...]]" >&2
        exit 2
        ;;
esac
