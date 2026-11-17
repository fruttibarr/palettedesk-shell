#!/usr/bin/env bash
# Creates picker thumbnails for video wallpapers (GIFs/images thumbnail themselves).
# Thumb name = md5 of the full path, matching Qt.md5() in WallpaperPicker.qml.
out="$HOME/.cache/rice/thumbs"
mkdir -p "$out"
find -L "$HOME/Pictures/Wallpapers" -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) -print0 |
while IFS= read -r -d '' f; do
  t="$out/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
  [ -s "$t" ] && continue
  nice -n 10 ffmpeg -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf scale=360:-2 -q:v 4 "$t" </dev/null 2>/dev/null \
    || nice -n 10 ffmpeg -loglevel error -y -i "$f" -frames:v 1 -vf scale=360:-2 -q:v 4 "$t" </dev/null 2>/dev/null
done
