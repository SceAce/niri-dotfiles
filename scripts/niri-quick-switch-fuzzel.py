#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys

ROFI_CONFIG = os.path.expanduser("~/.config/rofi/config-keybinds.rasi")
EXCLUDE_APPS = {
    "rofi",
    "fuzzel",
    "quick-switch",
    "niri-quick-switch",
    "niri-hotkey-menu",
}


def run_json(command: list[str]):
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError:
        return None
    return json.loads(result.stdout)


def get_active_output_workspace_ids() -> set[int]:
    workspaces = run_json(["niri", "msg", "-j", "workspaces"])
    if not workspaces:
        return set()

    active_output = None
    for ws in workspaces:
        if ws.get("is_focused"):
            active_output = ws.get("output")
            break

    if not active_output:
        return set()

    return {
        ws["id"]
        for ws in workspaces
        if ws.get("output") == active_output and isinstance(ws.get("id"), int)
    }


def get_window_sort_key(window: dict):
    ws_id = window.get("workspace_id", 0)

    if window.get("is_floating"):
        return (ws_id, 99999, 0, window.get("id"))

    layout = window.get("layout") or {}
    pos = layout.get("pos_in_scrolling_layout")
    if isinstance(pos, list) and len(pos) >= 2:
        return (ws_id, pos[0], pos[1], window.get("id"))

    return (ws_id, 9999, 0, window.get("id"))


def rofi_markup(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def main():
    if not shutil.which("rofi"):
        subprocess.run(["notify-send", "niri", "rofi 未安装或不在 PATH 中"])
        sys.exit(1)

    valid_ws_ids = get_active_output_workspace_ids()
    if not valid_ws_ids:
        sys.exit(0)

    windows = run_json(["niri", "msg", "-j", "windows"])
    if not windows:
        sys.exit(0)

    current_windows = []
    for window in windows:
        if window.get("workspace_id") not in valid_ws_ids:
            continue

        app_id = (window.get("app_id") or "").strip()
        if app_id in EXCLUDE_APPS:
            continue

        current_windows.append(window)

    if not current_windows:
        sys.exit(0)

    current_windows.sort(key=get_window_sort_key)

    lines = []
    for window in current_windows:
        app_id = rofi_markup(window.get("app_id") or "Wayland")
        title = rofi_markup((window.get("title") or "No Title").replace("\n", " "))
        ws_id = window.get("workspace_id", "?")
        lines.append(f"<span weight='bold'>[{app_id}]</span> {title} <span alpha='70%'>· ws {ws_id}</span>")

    config_args = ["-config", ROFI_CONFIG] if os.path.exists(ROFI_CONFIG) else []
    proc = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-markup-rows",
            "-p",
            "Window",
            "-mesg",
            "Alt+Tab window switcher",
            "-format",
            "i",
            *config_args,
        ],
        input="\n".join(lines),
        capture_output=True,
        text=True,
    )

    if proc.returncode != 0:
        sys.exit(0)

    raw_output = proc.stdout.strip()
    if not raw_output:
        sys.exit(0)

    try:
        selected_idx = int(raw_output)
    except ValueError:
        sys.exit(0)

    if 0 <= selected_idx < len(current_windows):
        target_id = current_windows[selected_idx].get("id")
        subprocess.run(
            ["niri", "msg", "action", "focus-window", "--id", str(target_id)],
            check=False,
        )


if __name__ == "__main__":
    main()
