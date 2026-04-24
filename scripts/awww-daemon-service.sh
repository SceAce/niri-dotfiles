#!/usr/bin/env bash

set -euo pipefail

desktop_pid=""
overview_pid=""

run_awww_daemon() {
    if command -v awww-daemon >/dev/null 2>&1; then
        awww-daemon "$@"
    elif command -v awww >/dev/null 2>&1; then
        awww daemon "$@"
    else
        echo "awww daemon command not found" >&2
        exit 127
    fi
}

cleanup() {
    if [[ -n "$desktop_pid" ]]; then
        kill "$desktop_pid" >/dev/null 2>&1 || true
    fi
    if [[ -n "$overview_pid" ]]; then
        kill "$overview_pid" >/dev/null 2>&1 || true
    fi
    wait >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

run_awww_daemon >/dev/null 2>&1 &
desktop_pid="$!"

run_awww_daemon -n overview >/dev/null 2>&1 &
overview_pid="$!"

wait -n "$desktop_pid" "$overview_pid"
exit 1
