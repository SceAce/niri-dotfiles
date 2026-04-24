#!/usr/bin/env bash

# 10 分钟锁屏，15 分钟熄屏，30 分钟休眠
exec swayidle -w \
timeout 600  '~/.config/niri/scripts/lock-screen.sh --daemonize' \
timeout 900  'niri msg action power-off-monitors' \
resume       'niri msg action power-on-monitors' \
timeout 1800 '~/.config/niri/scripts/lock-screen.sh --daemonize && systemctl suspend'
