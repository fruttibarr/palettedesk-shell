#!/usr/bin/env bash
# Usage: screenshot.sh region|full|window|edit   (edit = region, then annotate in satty if installed)
# Saves to ~/Pictures/Screenshots, copies to clipboard, sends a notification
# with a thumbnail (click it to open the image).
set -euo pipefail
mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

# selection color from the current wallpaper theme
accent=$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/state/rice/colors.json")))["primary"])' 2>/dev/null || echo "#cebdfe")

case "$mode" in
  region)
    geom=$(slurp -d -b '#00000066' -c "${accent}ff" -s '#00000000' -w 2) || exit 0   # Esc = cancel
    grim -g "$geom" "$file" ;;
  edit)
    geom=$(slurp -d -b '#00000066' -c "${accent}ff" -s '#00000000' -w 2) || exit 0
    grim -g "$geom" "$file"
    if command -v satty >/dev/null; then
      satty --filename "$file" --output-filename "$file" --copy-command wl-copy --early-exit || true
    else notify-send -a Screenshot "satty is not installed" "Saved without annotating"; fi ;;
  full)
    grim "$file" ;;
  window)
    geom=$(hyprctl activewindow -j | python3 -c 'import json,sys;w=json.load(sys.stdin);print(f"{w["at"][0]},{w["at"][1]} {w["size"][0]}x{w["size"][1]}")')
    grim -g "$geom" "$file" ;;
  *) echo "usage: $0 region|full|window|edit" >&2; exit 1 ;;
esac

wl-copy --type image/png < "$file"

(
  action=$(notify-send -a Screenshot -i "$file" -A default=Open -A folder="Show in folder" \
           "Screenshot saved" "$(basename "$file") · copied to clipboard" --wait || true)
  case "$action" in
    default) xdg-open "$file" ;;
    folder)  xdg-open "$dir" ;;
  esac
) >/dev/null 2>&1 &
