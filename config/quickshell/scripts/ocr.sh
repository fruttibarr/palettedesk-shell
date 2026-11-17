#!/usr/bin/env bash
# Select a screen region and copy the text in it to the clipboard (needs tesseract + tesseract-data-eng).
#   ocr.sh                 pick a region with the mouse
#   ocr.sh --image FILE    read text from an image file instead (also for testing)
#   OCR_LANG=deu ocr.sh    another language (install its tesseract-data-* package)
set -euo pipefail
command -v tesseract >/dev/null || { notify-send -a OCR -u critical "tesseract is not installed" "Install tesseract and tesseract-data-eng"; exit 1; }
tmp="$(mktemp --suffix=.png)"; trap 'rm -f "$tmp"' EXIT
if [ "${1:-}" = "--image" ]; then cp "${2:?usage: ocr.sh --image FILE}" "$tmp"
else
  accent=$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/state/rice/colors.json")))["primary"])' 2>/dev/null || echo "#cebdfe")
  geom=$(slurp -d -b '#00000066' -c "${accent}ff" -s '#00000000' -w 2) || exit 0   # Esc = cancel
  grim -g "$geom" "$tmp"
fi
text="$(tesseract "$tmp" - -l "${OCR_LANG:-eng}" 2>/dev/null | sed -e 's/[[:space:]]*$//' | cat -s)"
if [ -z "${text//[[:space:]]/}" ]; then notify-send -a OCR "No text found"; exit 0; fi
if [ "${1:-}" = "--image" ]; then printf '%s\n' "$text"; else printf '%s' "$text" | wl-copy; fi
notify-send -a OCR "Text copied" "$(printf '%s' "$text" | head -c 160)"
