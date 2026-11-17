#!/usr/bin/env bash
# Download the nine wallpapers the built-in themes use (one file each, not whole repos)
# into ~/Pictures/Wallpapers/<Owner-repo>/<path>, which is where the themes look for them.
# Each file comes straight from its author's public GitHub repo, onto your machine.
# They are other people's work: check each repo's license before you reuse or redistribute one.
# Re-running skips files you already have. Set WALLPAPER_DIR to download somewhere else.
set -euo pipefail
dest="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }

# owner/repo  branch  path-inside-repo
files=(
  "AngelJumbo/gruvbox-wallpapers main wallpapers/mix/desk-gruvbox-material.jpg"
  "AngelJumbo/gruvbox-wallpapers main wallpapers/pixelart/girl-reading-book.png"
  "Apeiros-46B/everforest-walls main nature/mist_forest_1.png"
  "DenverCoder1/minimalistic-wallpaper-collection main images/denis-istomin-midnight-gazing.png"
  "linuxdotexe/nordic-wallpapers master wallpapers/nord_valley.png"
  "orangci/walls-catppuccin-mocha master dominik-mayer-10.jpg"
  "rose-pine/wallpapers main illustration/leafy.png"
  "whoisYoges/lwalpapers PicturesOnly wallpapers/b-065.jpg"
  "elapse-d/foo-Wallpaper-Feh-Gif dev-test gif/trains.gif"
)
fail=0
for entry in "${files[@]}"; do
  read -r repo branch path <<<"$entry"
  folder="${repo//\//-}"
  out="$dest/$folder/$path"
  [ -s "$out" ] && { echo "have  $folder/$path"; continue; }
  [ "$folder" = "elapse-d-foo-Wallpaper-Feh-Gif" ] && out="$dest/Animated/$folder/$path"
  [ -s "$out" ] && { echo "have  $folder/$path"; continue; }
  echo "fetch $repo: $path"
  mkdir -p "$(dirname "$out")"
  if curl -fsSL --max-time 120 -o "$out.part" "https://raw.githubusercontent.com/$repo/$branch/$path"; then
    mv "$out.part" "$out"
  else
    rm -f "$out.part"; echo "  failed: $repo/$path" >&2; fail=1
  fi
done
exit $fail
