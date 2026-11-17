#!/usr/bin/env bash
# Bake a blurred copy of the current wallpaper into the PaletteDesk Spicetify theme
# (as a data: URI between PD-WALL markers in user.css), then `spicetify apply`.
set -euo pipefail
css="$HOME/.config/spicetify/Themes/palettedesk/user.css"
colors="$HOME/.local/state/rice/colors.json"
[ -f "$css" ] && [ -f "$colors" ] || exit 0
still="${1:-$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('still',''))" "$colors")}"
[ -f "$still" ] || exit 0
# Album-cover wallpapers are temporary and change every track: don't rebuild for them.
case "$still" in */albumart/*) exit 0 ;; esac
# One run at a time; skip when this exact image is already baked in.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/rice-spicetify-wall.lock"; flock -n 9 || exit 0
state="$HOME/.local/state/rice/spicetify-wall.sum"
sum=$(cat "$still" "$HOME/.config/spicetify/Themes/palettedesk/color.ini" | cksum)
[ "$(cat "$state" 2>/dev/null)" = "$sum" ] && grep -q 'data:image/jpeg' "$css" && exit 0
tmp=$(mktemp --suffix=.jpg)
trap 'rm -f "$tmp"' EXIT
ffmpeg -loglevel error -y -i "$still" -vf "scale=640:-1,gblur=sigma=6,eq=brightness=-0.12:saturation=1.15" -q:v 6 "$tmp"
python3 - "$css" "$tmp" <<'PY'
import base64, re, sys
css, img = sys.argv[1:3]
b64 = base64.b64encode(open(img, "rb").read()).decode()
block = f"""/* PD-WALL-BEGIN */
:root {{ --pd-wall: linear-gradient(rgba(0,0,0,.30), rgba(0,0,0,.30)), url("data:image/jpeg;base64,{b64}"); }}
/* PD-WALL-END */"""
s = open(css).read()
s = re.sub(r"\n*/\* PD-WALL-BEGIN \*/.*?/\* PD-WALL-END \*/", "", s, flags=re.S)
open(css, "w").write(s.rstrip() + "\n\n" + block + "\n")
PY
spicetify apply >/dev/null 2>&1 || true
printf '%s\n' "$sum" > "$state"
