#!/usr/bin/env bash
# Album-cover wallpaper (Settings → Wallpaper & Colors → Album cover wallpaper).
#   album-wallpaper.sh <art-url> [style]   cover of the current track becomes the wallpaper
#   album-wallpaper.sh --restore           back to the wallpaper it replaced
# style: "cover" (sharp cover floating on a blurred copy of itself, default) or "fill" (cover fills the screen)
# The picture is built with ffmpeg at the monitor's resolution, then handed to
# set-wallpaper.sh so every color follows it like any other wallpaper.
set -euo pipefail
here="$(dirname "$(realpath "$0")")"
cache="$HOME/.cache/rice/albumart"
state="$HOME/.local/state/rice/colors.json"
mkdir -p "$cache"

field() { python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2],""))' "$state" "$1" 2>/dev/null || true; }

if [ "${1:-}" = "--restore" ]; then
  cur=$(field wallpaper); base=$(field base)
  case "$cur" in "$cache"/*) ;; *) exit 0 ;; esac          # not showing a cover: nothing to do
  if [ -f "$base" ]; then exec "$here/set-wallpaper.sh" "$base"; fi
  exec "$here/set-wallpaper.sh"                             # the old one is gone: random
fi

url="${1:?art url}"
style="${2:-cover}"

# ---- fetch the cover (cached by URL; local files by content, players reuse temp names) ----
tmp=$(mktemp "$cache/.dl.XXXXXX")
trap 'rm -f "$tmp"' EXIT
case "$url" in
  http://*|https://*)
    key=$(printf '%s' "$url" | md5sum | cut -d' ' -f1)
    art="$cache/$key.art"
    if [ ! -s "$art" ]; then
      curl -fsSL --max-time 15 -A "rice-shell" -o "$tmp" "$url"
      mv "$tmp" "$art"
    fi ;;
  file://*|/*)
    src=$(python3 -c 'import sys,urllib.parse as u;p=sys.argv[1];print(u.unquote(u.urlparse(p).path) if p.startswith("file://") else p)' "$url")
    [ -s "$src" ] || { echo "no such cover: $src" >&2; exit 1; }
    key=$(md5sum "$src" | cut -d' ' -f1)
    art="$cache/$key.art"
    [ -s "$art" ] || { cp "$src" "$tmp"; mv "$tmp" "$art"; } ;;
  *) echo "unsupported art url: $url" >&2; exit 1 ;;
esac

# ---- size: the biggest monitor ----
read -r W H < <(hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    m = max(json.load(sys.stdin), key=lambda m: m["width"] * m["height"])
    w, h = (m["height"], m["width"]) if m.get("transform", 0) % 2 else (m["width"], m["height"])
    print(w, h)
except Exception:
    print(1920, 1080)')
W=$((W / 2 * 2)); H=$((H / 2 * 2))

out="$cache/$key-$style-${W}x${H}.jpg"
if [ ! -s "$out" ]; then
  if [ "$style" = "fill" ]; then
    graph="[0:v]scale=$W:$H:force_original_aspect_ratio=increase:flags=lanczos,crop=$W:$H[out]"
  else
    short=$(( W < H ? W : H ))
    S=$(( short * 56 / 100 / 2 * 2 ))      # cover edge
    R=$(( S * 4 / 100 ))                   # corner radius
    P=$(( S * 12 / 100 ))                  # room around the cover for its shadow
    # rounded-rectangle alpha with a 1px soft edge
    mask="255*clip($R+0.5-hypot(max(abs(X-$S/2+0.5)-($S/2-$R),0),max(abs(Y-$S/2+0.5)-($S/2-$R),0)),0,1)"
    graph="[0:v]split=2[a][b];
      [a]scale=$((W / 8)):$((H / 8)):force_original_aspect_ratio=increase,crop=$((W / 8)):$((H / 8)),gblur=sigma=14,
         scale=$W:$H:flags=bicubic,eq=brightness=-0.10:saturation=1.2,format=gbrp[bg];
      [b]scale=$S:$S:flags=lanczos,format=gbrap,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='$mask',split=2[fg][fg2];
      [fg2]pad=$((S + 2 * P)):$((S + 2 * P)):$P:$P:color=black@0,
         colorchannelmixer=rr=0:rg=0:rb=0:gr=0:gg=0:gb=0:br=0:bg=0:bb=0:aa=0.55,gblur=sigma=$((P / 3))[sh];
      [bg][sh]overlay=(W-w)/2:(H-h)/2+$((P / 4))[bs];
      [bs][fg]overlay=(W-w)/2:(H-h)/2[out]"
  fi
  ffmpeg -loglevel error -y -i "$art" -filter_complex "$graph" -map "[out]" -frames:v 1 -q:v 2 "$out.tmp.jpg"
  mv "$out.tmp.jpg" "$out"
fi
touch "$out" "$art"

# keep the cache small: the 150 most recently used files
ls -t "$cache" | tail -n +151 | while read -r f; do rm -f "$cache/$f"; done

[ "$(field wallpaper)" = "$out" ] && exit 0
# set-wallpaper.sh takes the colors from this small copy of the cover itself
colors="$cache/$key.png"
[ -s "$colors" ] || ffmpeg -loglevel error -y -i "$art" -vf scale=256:256 -frames:v 1 "$colors"
exec "$here/set-wallpaper.sh" "$out"
