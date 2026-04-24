#!/usr/bin/env bash

set -euo pipefail

source "${HOME}/.config/niri/scripts/lib/niri-config.sh"

IFS=':' read -r -a zen_candidates <<<"$NIRI_ZEN_CANDIDATES"

for candidate in "${zen_candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
        exec "$candidate"
    fi
done

exec xdg-open 'https://'
