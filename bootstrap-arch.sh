#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE_ARGS=()
OUTPUT_PROFILE="current-machine"
INSTALL_MOUSE_ACTIONS=1
INSTALL_CONFIG=1

PACMAN_PACKAGES=(
    awww
    brightnessctl
    cliphist
    copyq
    curl
    fcitx5
    fcitx5-configtool
    fcitx5-gtk
    fcitx5-qt
    ghostty
    git
    grim
    hyprlock
    hyprpicker
    jq
    libnotify
    mako
    niri
    pavucontrol
    playerctl
    polkit-gnome
    power-profiles-daemon
    python
    python-gobject
    quickshell
    rofi
    rust
    satty
    slurp
    swayosd
    swayidle
    thunar
    wl-clipboard
    wlsunset
    xdg-desktop-portal-gnome
    xorg-xhost
)

usage() {
    cat <<'EOF'
Usage: ./bootstrap-arch.sh [options]

Options:
  --copy                  Copy files instead of symlinking them into ~/.config.
  --force                 Replace existing installed files directly.
  --output-profile NAME   Install the selected output profile.
  --no-mouse-actions      Skip installing mouse-actions and its udev rule.
  --deps-only             Install packages only, do not run ./install.sh.
  -h, --help              Show this help.
EOF
}

log() {
    printf '[bootstrap] %s\n' "$*"
}

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

run_root() {
    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    elif [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
    else
        printf 'Need root privileges for: %s\n' "$*" >&2
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --copy|--force)
                MODE_ARGS+=("$1")
                ;;
            --output-profile)
                shift
                OUTPUT_PROFILE="${1:-}"
                [[ -n "$OUTPUT_PROFILE" ]] || {
                    echo "--output-profile requires a profile name" >&2
                    exit 2
                }
                ;;
            --no-mouse-actions)
                INSTALL_MOUSE_ACTIONS=0
                ;;
            --deps-only)
                INSTALL_CONFIG=0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf 'Unknown argument: %s\n' "$1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

install_pacman_packages() {
    log "installing Arch packages via pacman"
    run_root pacman -S --needed "${PACMAN_PACKAGES[@]}"
}

install_mouse_actions() {
    [[ "$INSTALL_MOUSE_ACTIONS" -eq 1 ]] || return 0

    need_cmd cargo
    need_cmd install
    need_cmd usermod
    need_cmd udevadm

    log "installing mouse-actions from upstream git"
    cargo install --git https://github.com/jersou/mouse-actions --locked mouse-actions

    log "installing udev rule for /dev/uinput access"
    run_root install -Dm644 "$REPO_ROOT/udev/80-mouse-actions.rules" /etc/udev/rules.d/80-mouse-actions.rules
    run_root udevadm control --reload
    run_root udevadm trigger --subsystem-match=misc --sysname-match=uinput || true

    if ! id -nG "$USER" | grep -Eq '(^| )(input|plugdev)( |$)'; then
        log "adding $USER to input group for mouse-actions"
        run_root usermod -aG input "$USER"
    fi
}

enable_services() {
    log "enabling power-profiles-daemon"
    run_root systemctl enable --now power-profiles-daemon.service
}

install_repo_config() {
    [[ "$INSTALL_CONFIG" -eq 1 ]] || return 0

    log "installing repo config"
    "$REPO_ROOT/install.sh" "${MODE_ARGS[@]}" --output-profile "$OUTPUT_PROFILE"
}

main() {
    parse_args "$@"
    need_cmd pacman
    install_pacman_packages
    install_mouse_actions
    enable_services
    install_repo_config

    log "done"
    if [[ "$INSTALL_MOUSE_ACTIONS" -eq 1 ]]; then
        log "mouse-actions needs a re-login after group changes to fully take effect"
    fi
}

main "$@"
