#!/usr/bin/env bash
# Usage: set-wallpaper.sh [file] [scheme]
#   file:   image, GIF or video (no file = random wallpaper)
#   scheme: matugen scheme type (no scheme = from ~/.config/rice/settings.json)
# Colors are generated from the image, or from a frame of a GIF/video.
#
# Files under ~/.cache/rice/albumart are temporary album-cover wallpapers (see
# album-wallpaper.sh): the wallpaper they replace stays remembered as "base" in
# colors.json, and colors come from the cover itself rather than its backdrop.
set -euo pipefail

# Per-monitor wallpapers live in their own file: matugen rewrites colors.json on every global change.
#   set-wallpaper.sh --monitor NAME FILE   wallpaper for one monitor only (colors stay as they are)
#   set-wallpaper.sh --monitor NAME        remove that monitor's own wallpaper
#   set-wallpaper.sh --all [FILE]          forget every per-monitor wallpaper, then set FILE everywhere
walls="${XDG_STATE_HOME:-$HOME/.local/state}/rice/walls.json"
if [ "${1:-}" = "--monitor" ]; then
  mkdir -p "$(dirname "$walls")"
  python3 - "$walls" "${2:?monitor name}" "${3:-}" <<'PY'
import json, os, sys
p, mon, f = sys.argv[1:4]
try: d = json.load(open(p))
except Exception: d = {}
if f: d[mon] = os.path.realpath(f)
else: d.pop(mon, None)
tmp = p + ".tmp"; json.dump(d, open(tmp, "w"), indent=2); os.replace(tmp, p)
PY
  exit 0
fi
if [ "${1:-}" = "--all" ]; then rm -f "$walls"; shift; [ $# -gt 0 ] || set -- ""; fi
dir="$HOME/Pictures/Wallpapers"
cache="$HOME/.cache/rice"
state="$HOME/.local/state/rice/colors.json"
mkdir -p "$cache/stills"

file="${1:-$(find -L "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | shuf -n1)}"
[ -f "$file" ] || { echo "not a file: $file" >&2; exit 1; }
file="$(realpath "$file")"

scheme="${2:-}"
[ -n "$scheme" ] || scheme=$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.config/rice/settings.json"))).get("colorScheme","scheme-tonal-spot"))' 2>/dev/null || echo scheme-tonal-spot)

# One re-theme at a time (track changes and the picker can overlap)
exec 9>"$cache/set-wallpaper.lock"
flock 9

# The wallpaper to go back to when the music stops: an album cover keeps the
# one already remembered, anything else becomes it.
base="$file"
source=""
case "$file" in "$cache/albumart/"*)
  base=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(d.get("base") or d.get("wallpaper",""))' "$state" 2>/dev/null || true)
  name="$(basename "$file")"
  [ -s "$cache/albumart/${name%%-*}.png" ] && source="$cache/albumart/${name%%-*}.png" ;;
esac

# Animated? Grab a representative frame for colors / lock screen / previews.
still="$file"
case "${file,,}" in
  *.mp4|*.webm|*.mkv|*.mov|*.gif)
    still="$cache/stills/$(printf '%s' "$file" | md5sum | cut -d' ' -f1).jpg"
    if [ ! -s "$still" ]; then
      ffmpeg -loglevel error -y -ss 1 -i "$file" -frames:v 1 -q:v 3 "$still" 2>/dev/null \
        || ffmpeg -loglevel error -y -i "$file" -frames:v 1 -q:v 3 "$still"
    fi ;;
esac

matugen image "${source:-$still}" --mode dark --type "$scheme" --source-color-index 0

# colors.json names the image the colors came from; point it at the real files.
python3 - "$file" "$still" "$base" <<'PY'
import json, os, sys
p = os.path.expanduser("~/.local/state/rice/colors.json")
d = json.load(open(p))
d["wallpaper"], d["still"], d["base"] = sys.argv[1], sys.argv[2], sys.argv[3]
tmp = p + ".tmp"
json.dump(d, open(tmp, "w"), indent=2)
os.replace(tmp, p)
PY
