#!/usr/bin/env bash

set -euo pipefail

if [[ -x /home/source/tools/zen/zen ]]; then
    exec /home/source/tools/zen/zen
elif [[ -x /home/source/opt/zen/zen ]]; then
    exec /home/source/opt/zen/zen
else
    exec xdg-open 'https://'
fi
