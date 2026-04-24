#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
NIRI_TARGET_DIR="$CONFIG_HOME/niri"
HYPR_TARGET_DIR="$CONFIG_HOME/hypr"
ROFI_TARGET_DIR="$CONFIG_HOME/rofi"
NOCTALIA_TARGET_DIR="$CONFIG_HOME/noctalia"
SYSTEMD_USER_DIR="$CONFIG_HOME/systemd/user"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/niri-dotfiles-backups"
MODE="symlink"
FORCE=0
OUTPUT_PROFILE="current-machine"

CONFIG_ITEMS=(
    "Keybinds_README.md"
    "animations.kdl"
    "binds.kdl"
    "colors.kdl"
    "config.kdl"
    "gestures.kdl"
    "hyprlock.conf"
    "input.kdl"
    "layout.kdl"
    "mouse-actions.json"
    "quickshell"
    "rule.kdl"
    "tray-cycle-order.json"
    "scripts"
    "systemd"
    "outputs"
)

usage() {
    cat <<'EOF'
Usage: ./install.sh [--copy] [--force] [--output-profile <name>] [--list-output-profiles]

Options:
  --copy   Copy files instead of creating symlinks.
  --force  Replace existing files directly instead of backing them up first.
  --output-profile <name>
           Install the selected output profile as ~/.config/niri/output.kdl.
  --list-output-profiles
           Print available output profiles and exit.
  -h, --help
EOF
}

log() {
    printf '[install] %s\n' "$*"
}

backup_path() {
    local target="$1"
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_ROOT"
    printf '%s/%s-%s\n' "$BACKUP_ROOT" "$(basename "$target")" "$stamp"
}

backup_existing() {
    local target="$1"
    local backup

    [[ -e "$target" || -L "$target" ]] || return 0
    [[ "$FORCE" -eq 1 ]] && return 0

    backup="$(backup_path "$target")"
    mv "$target" "$backup"
    log "backed up $target -> $backup"
}

clear_target() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
    fi
}

install_one() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    if [[ "$MODE" == "symlink" ]]; then
        if [[ -L "$dst" ]] && [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
            log "kept $dst"
            return 0
        fi
        backup_existing "$dst"
        clear_target "$dst"
        ln -sfn "$src" "$dst"
        log "linked $dst -> $src"
        return 0
    fi

    if [[ "$FORCE" -eq 1 ]]; then
        clear_target "$dst"
    fi

    if [[ -d "$src" ]]; then
        backup_existing "$dst"
        cp -a "$src" "$dst"
    else
        backup_existing "$dst"
        cp -a "$src" "$dst"
    fi
    log "copied $src -> $dst"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --copy)
                MODE="copy"
                ;;
            --force)
                FORCE=1
                ;;
            --output-profile)
                shift
                OUTPUT_PROFILE="${1:-}"
                if [[ -z "$OUTPUT_PROFILE" ]]; then
                    echo "--output-profile requires a profile name" >&2
                    exit 2
                fi
                ;;
            --list-output-profiles)
                list_output_profiles
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf 'Unknown argument: %s\n\n' "$1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

list_output_profiles() {
    local profile_dir="$REPO_ROOT/outputs/profiles"
    find "$profile_dir" -maxdepth 1 -type f -name '*.kdl' -printf '%f\n' | sed 's/\.kdl$//' | sort
}

install_config_tree() {
    local item
    mkdir -p "$NIRI_TARGET_DIR"

    for item in "${CONFIG_ITEMS[@]}"; do
        install_one "$REPO_ROOT/$item" "$NIRI_TARGET_DIR/$item"
    done
}

install_output_profile() {
    local src="$REPO_ROOT/outputs/profiles/$OUTPUT_PROFILE.kdl"
    local dst="$NIRI_TARGET_DIR/output.kdl"

    if [[ ! -f "$src" ]]; then
        echo "Unknown output profile: $OUTPUT_PROFILE" >&2
        echo "Available profiles:" >&2
        list_output_profiles >&2
        exit 2
    fi

    install_one "$src" "$dst"
    log "selected output profile: $OUTPUT_PROFILE"
}

install_rofi() {
    install_one "$REPO_ROOT/rofi" "$ROFI_TARGET_DIR"
}

install_noctalia_config() {
    install_one "$REPO_ROOT/noctalia-config" "$NOCTALIA_TARGET_DIR"
}

install_hyprlock() {
    mkdir -p "$HYPR_TARGET_DIR"
    install_one "$REPO_ROOT/hyprlock.conf" "$HYPR_TARGET_DIR/hyprlock.conf"
}

install_systemd_units() {
    local unit
    mkdir -p "$SYSTEMD_USER_DIR"

    for unit in "$REPO_ROOT"/systemd/*.service; do
        install_one "$unit" "$SYSTEMD_USER_DIR/$(basename "$unit")"
    done

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user daemon-reload; then
            log "reloaded systemd --user units"
        else
            log "skipped systemd --user daemon-reload (no user bus in current environment)"
        fi
    fi
}

main() {
    parse_args "$@"
    install_config_tree
    install_output_profile
    install_hyprlock
    install_rofi
    install_noctalia_config
    install_systemd_units

    log "done"
    log "niri config: $NIRI_TARGET_DIR"
    log "hyprlock config: $HYPR_TARGET_DIR/hyprlock.conf"
    log "rofi config: $ROFI_TARGET_DIR"
    log "noctalia config: $NOCTALIA_TARGET_DIR"
}

main "$@"
