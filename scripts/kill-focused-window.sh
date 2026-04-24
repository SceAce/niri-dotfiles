#!/usr/bin/env bash
set -euo pipefail

focused_json="$(niri msg -j focused-window)"
pid="$(jq -r '.pid // empty' <<<"$focused_json")"

if [[ -z "$pid" ]]; then
  notify-send "niri" "未找到当前窗口的 PID"
  exit 1
fi

kill -TERM "$pid"
