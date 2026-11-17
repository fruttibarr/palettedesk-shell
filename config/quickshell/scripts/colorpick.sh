#!/usr/bin/env bash
# Pick a color anywhere on screen; copies its hex code (needs hyprpicker).
set -euo pipefail
command -v hyprpicker >/dev/null || { notify-send -a "Color picker" -u critical "hyprpicker is not installed"; exit 1; }
hex="$(hyprpicker -f hex)" || exit 0     # Esc = cancel
[ -n "$hex" ] || exit 0
printf '%s' "$hex" | wl-copy
notify-send -a "Color picker" "$hex" "Copied to the clipboard"
