#!/usr/bin/env python3

import json
import re
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")

from gi.repository import Gdk, Gio, Gtk  # noqa: E402

ORDER_FILE = Path.home() / ".config" / "niri" / "tray-cycle-order.json"
LOG_FILE = Path("/tmp/niri-tray-cycle.log")
DEFAULT_ORDER = [
    "QQ",
    "wechat",
]
TRAY_PATTERNS = {
    "QQ": ["qq", "linuxqq", "tencent-qq", "tencent qq", "chrome_status_icon"],
    "wechat": ["wechat", "weixin", "wxwork", "tencent-wechat", "tencent wechat"],
}
APP_ICONS = {
    "QQ": "/home/source/tools/LinuxQQ/qq.png",
    "wechat": "/home/source/tools/Wechat/wechat.png",
}
HIDDEN_PATTERNS = [
    "copyq",
    "fcitx",
    "input method",
    "输入法",
    "clipboard",
    "剪贴板",
]


def log(message: str) -> None:
    with LOG_FILE.open("a", encoding="utf-8") as fh:
        fh.write(message + "\n")


def run_text(command: list[str]) -> tuple[int, str, str]:
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def load_order() -> list[str]:
    if not ORDER_FILE.exists():
        return DEFAULT_ORDER
    try:
        data = json.loads(ORDER_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        return DEFAULT_ORDER
    if isinstance(data, list):
        order = [str(item).strip() for item in data if str(item).strip()]
        if order:
            return order
    return DEFAULT_ORDER


def get_tray_items() -> list[str]:
    rc, stdout, stderr = run_text(
        [
            "gdbus",
            "call",
            "--session",
            "--dest",
            "org.kde.StatusNotifierWatcher",
            "--object-path",
            "/StatusNotifierWatcher",
            "--method",
            "org.freedesktop.DBus.Properties.Get",
            "org.kde.StatusNotifierWatcher",
            "RegisteredStatusNotifierItems",
        ]
    )
    log(f"watcher rc={rc} stdout={stdout!r} stderr={stderr!r}")
    if rc != 0 or not stdout:
        return []
    return re.findall(r"'([^']+)'", stdout)


def split_item(item: str) -> tuple[str, str] | None:
    if "/" not in item:
        return None
    bus_name, object_path = item.split("/", 1)
    return bus_name, "/" + object_path


def get_metadata(item: str) -> dict[str, str]:
    split = split_item(item)
    if split is None:
        return {}
    bus_name, object_path = split
    metadata: dict[str, str] = {}
    for prop in ["Id", "Title", "IconName", "Status"]:
        rc, stdout, stderr = run_text(
            [
                "gdbus",
                "call",
                "--session",
                "--dest",
                bus_name,
                "--object-path",
                object_path,
                "--method",
                "org.freedesktop.DBus.Properties.Get",
                "org.kde.StatusNotifierItem",
                prop,
            ]
        )
        log(f"prop item={item!r} prop={prop} rc={rc} stdout={stdout!r} stderr={stderr!r}")
        if rc == 0 and stdout:
            metadata[prop] = stdout
    return metadata


def normalize(value: str) -> str:
    return value.lower().replace("'", " ").replace('"', " ")


def unwrap_variant(value: str) -> str:
    match = re.search(r"<\'(.*?)\'>", value)
    if match:
        return match.group(1)
    return value


def collect_candidates() -> list[dict]:
    order = load_order()
    tray_items = get_tray_items()
    log(f"tray_items={tray_items}")
    items = []
    for item in tray_items:
        metadata = get_metadata(item)
        items.append({"item": item, "metadata": metadata})
    log("tray_metadata=" + json.dumps(items, ensure_ascii=False))

    matched: list[dict] = []
    used: set[str] = set()
    for name in order:
        patterns = [name.lower(), *TRAY_PATTERNS.get(name, [])]
        for item in items:
            if item["item"] in used:
                continue
            haystack = " ".join(
                normalize(part)
                for part in [
                    item["item"],
                    unwrap_variant(item["metadata"].get("Id", "")),
                    unwrap_variant(item["metadata"].get("Title", "")),
                    unwrap_variant(item["metadata"].get("IconName", "")),
                ]
            )
            if any(pattern in haystack for pattern in patterns):
                matched.append(
                    {
                        "name": name,
                        "item": item["item"],
                        "metadata": item["metadata"],
                        "icon_path": APP_ICONS.get(name, ""),
                        "icon_name": unwrap_variant(item["metadata"].get("IconName", "")),
                    }
                )
                used.add(item["item"])
                break

    for item in items:
        if item["item"] in used:
            continue
        title = unwrap_variant(item["metadata"].get("Title", "")).strip()
        item_id = unwrap_variant(item["metadata"].get("Id", "")).strip()
        icon_name = unwrap_variant(item["metadata"].get("IconName", "")).strip()
        haystack = normalize(" ".join([item["item"], title, item_id, icon_name]))
        if any(pattern in haystack for pattern in HIDDEN_PATTERNS):
            log(f"hidden-item={item['item']!r}")
            continue
        display_name = title or item_id or item["item"].split("/", 1)[0]
        matched.append(
            {
                "name": display_name,
                "item": item["item"],
                "metadata": item["metadata"],
                "icon_path": "",
                "icon_name": icon_name,
            }
        )
        used.add(item["item"])
    log("matched=" + json.dumps(matched, ensure_ascii=False))
    return matched


def activate(item: str) -> None:
    split = split_item(item)
    if split is None:
        return
    bus_name, object_path = split
    rc, stdout, stderr = run_text(
        [
            "gdbus",
            "call",
            "--session",
            "--dest",
            bus_name,
            "--object-path",
            object_path,
            "--method",
            "org.kde.StatusNotifierItem.Activate",
            "0",
            "0",
        ]
    )
    log(f"activate item={item!r} rc={rc} stdout={stdout!r} stderr={stderr!r}")


def find_desktop_icon(candidate: dict) -> tuple[str, str]:
    metadata = candidate.get("metadata", {})
    names = [
        candidate.get("name", ""),
        unwrap_variant(metadata.get("Id", "")),
        unwrap_variant(metadata.get("Title", "")),
    ]
    desktop_dirs = [
        Path.home() / ".local/share/applications",
        Path("/usr/share/applications"),
    ]
    desktop_files: list[Path] = []
    for directory in desktop_dirs:
        if not directory.exists():
            continue
        desktop_files.extend(directory.glob("*.desktop"))

    for name in names:
        needle = normalize(name)
        if not needle:
            continue
        for desktop in desktop_files:
            try:
                text = desktop.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            lower = normalize(text)
            if needle not in lower:
                continue
            icon_value = ""
            for line in text.splitlines():
                if line.startswith("Icon="):
                    icon_value = line.split("=", 1)[1].strip()
                    break
            if not icon_value:
                continue
            if icon_value.startswith("/"):
                if Path(icon_value).exists():
                    return icon_value, ""
            else:
                return "", icon_value
    return "", ""


def slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def find_icon_file_by_name(candidate: dict) -> str:
    metadata = candidate.get("metadata", {})
    names = [
        candidate.get("name", ""),
        unwrap_variant(metadata.get("Id", "")),
        unwrap_variant(metadata.get("Title", "")),
    ]
    needles = {slugify(name) for name in names if name}
    if not needles:
        return ""

    search_roots = [
        Path.home() / ".local/share/icons",
        Path("/usr/share/icons"),
        Path("/usr/share/pixmaps"),
        Path.home() / "tools",
    ]
    exts = {".png", ".svg", ".xpm", ".ico", ".jpg", ".jpeg"}
    for root in search_roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in exts:
                continue
            stem = slugify(path.stem)
            if stem in needles:
                return str(path)
    return ""


def resolve_icon(candidate: dict) -> tuple[str, str]:
    icon_path = candidate.get("icon_path") or ""
    if icon_path and Path(icon_path).exists():
        return icon_path, ""

    icon_name = candidate.get("icon_name") or ""
    if icon_name:
        return "", icon_name

    desktop_icon_path, desktop_icon_name = find_desktop_icon(candidate)
    if desktop_icon_path or desktop_icon_name:
        return desktop_icon_path, desktop_icon_name

    named_icon_path = find_icon_file_by_name(candidate)
    if named_icon_path:
        return named_icon_path, ""

    return "", ""


class TraySwitcher(Gtk.Application):
    def __init__(self, candidates: list[dict]) -> None:
        super().__init__(application_id="local.niri.tray.switcher", flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.candidates = candidates
        self.buttons: list[Gtk.Button] = []
        self.pictures: list[Gtk.Picture] = []
        self.selected_index = 0
        self.window: Gtk.ApplicationWindow | None = None
        self.connect("activate", self.on_activate)

    def on_activate(self, _app: Gtk.Application) -> None:
        provider = Gtk.CssProvider()
        provider.load_from_data(
            b"""
            window.tray-switcher {
              background: rgba(6, 12, 20, 0.58);
              border: 1px solid rgba(198, 226, 255, 0.16);
              border-radius: 999px;
              box-shadow: 0 18px 48px rgba(0, 0, 0, 0.28);
            }
            box.tray-strip {
              padding: 6px 10px;
              border-radius: 999px;
            }
            button.tray-item {
              background: transparent;
              border: 1px solid transparent;
              border-radius: 999px;
              padding: 2px;
              min-width: 72px;
              min-height: 72px;
              box-shadow: none;
            }
            button.tray-item:selected,
            button.tray-item.selected {
              background: rgba(196, 226, 255, 0.14);
              border-color: rgba(196, 226, 255, 0.20);
              box-shadow: 0 8px 18px rgba(170, 210, 255, 0.08);
            }
            """
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_modal(True)
        self.window.set_hide_on_close(True)
        self.window.add_css_class("tray-switcher")
        self.window.set_default_size(max(150, len(self.candidates) * 78 + 20), 78)

        key = Gtk.EventControllerKey()
        key.connect("key-pressed", self.on_key_pressed)
        self.window.add_controller(key)

        outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        outer.add_css_class("tray-strip")
        outer.set_halign(Gtk.Align.CENTER)
        outer.set_valign(Gtk.Align.CENTER)

        for index, candidate in enumerate(self.candidates):
            button = Gtk.Button()
            button.add_css_class("tray-item")
            button.connect("clicked", self.on_button_clicked, index)

            icon = Gtk.Image()
            icon.set_pixel_size(56)
            icon_path, icon_name = resolve_icon(candidate)
            if icon_path and Path(icon_path).exists():
                icon.set_from_file(icon_path)
            elif icon_name:
                icon.set_from_icon_name(icon_name)
            else:
                icon.set_from_icon_name("application-x-executable")

            button.set_child(icon)
            outer.append(button)
            self.buttons.append(button)
            self.pictures.append(icon)

        self.window.set_child(outer)
        self.update_selection()
        self.window.present()

    def update_selection(self) -> None:
        for idx, button in enumerate(self.buttons):
            picture = self.pictures[idx]
            if idx == self.selected_index:
                button.add_css_class("selected")
                picture.set_pixel_size(62)
                button.grab_focus()
            else:
                button.remove_css_class("selected")
                picture.set_pixel_size(56)

    def activate_selected(self) -> None:
        activate(self.candidates[self.selected_index]["item"])
        self.quit()

    def on_button_clicked(self, _button: Gtk.Button, index: int) -> None:
        self.selected_index = index
        self.update_selection()
        self.activate_selected()

    def on_key_pressed(self, _controller, keyval, _keycode, _state) -> bool:
        if keyval in (Gdk.KEY_Right, Gdk.KEY_Tab):
            self.selected_index = (self.selected_index + 1) % len(self.candidates)
            self.update_selection()
            return True
        if keyval in (Gdk.KEY_Left, Gdk.KEY_ISO_Left_Tab):
            self.selected_index = (self.selected_index - 1) % len(self.candidates)
            self.update_selection()
            return True
        if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter, Gdk.KEY_space):
            self.activate_selected()
            return True
        if keyval in (Gdk.KEY_Escape,):
            self.quit()
            return True
        return False


def main() -> int:
    log("bind-fired")
    candidates = collect_candidates()
    if not candidates:
        subprocess.run(["notify-send", "niri", "未匹配到 QQ/微信 的托盘项"], check=False)
        return 0
    app = TraySwitcher(candidates)
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
