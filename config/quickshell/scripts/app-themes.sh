#!/usr/bin/env bash
# Render colour files for the apps the user opted into (settings key appThemes), from the current colors.
# Usage: app-themes.sh [image]     (image defaults to the current still wallpaper)
# Only writes into each app's own theme folder. Does nothing when no app is enabled.
set -u
settings="$HOME/.config/rice/settings.json"
T="$HOME/.config/matugen/templates/apps"
enabled="$(python3 -I - "$settings" <<'PY'
import json, sys
try: print(" ".join(x for x in json.loads(json.load(open(sys.argv[1])).get("appThemes", "[]")) if x.isalnum()))
except Exception: pass
PY
)"
[ -n "$enabled" ] || exit 0
img="${1:-$(python3 -I -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/state/rice/colors.json"))).get("still",""))' 2>/dev/null)}"
[ -f "$img" ] || { echo "app-themes: no wallpaper image to take colours from" >&2; exit 1; }
scheme="$(python3 -I -c 'import json,sys;print(json.load(open(sys.argv[1])).get("colorScheme","scheme-tonal-spot"))' "$settings" 2>/dev/null || echo scheme-tonal-spot)"
cfg="$(mktemp)"; trap 'rm -f "$cfg"' EXIT
echo "[config]" > "$cfg"
add() { printf '\n[templates.%s]\ninput_path = "%s"\noutput_path = "%s"\n' "$1" "$2" "$3" >> "$cfg"; mkdir -p "$(dirname "$3")"; }
for a in $enabled; do
  case "$a" in
    btop)      add btop "$T/btop.theme" "$HOME/.config/btop/themes/palettedesk.theme" ;;
    vscode)    add vscode "$T/vscode-theme.json" "$HOME/.vscode/extensions/palettedesk.theme/themes/palettedesk-color-theme.json"
               ext="$HOME/.vscode/extensions/palettedesk.theme"
               [ -f "$ext/package.json" ] || printf '%s\n' '{"name":"palettedesk-theme","displayName":"PaletteDesk","publisher":"palettedesk","version":"1.0.0","engines":{"vscode":"^1.60.0"},"contributes":{"themes":[{"label":"PaletteDesk","uiTheme":"vs-dark","path":"./themes/palettedesk-color-theme.json"}]}}' > "$ext/package.json" ;;
    vesktop)   add vesktop "$T/vesktop.theme.css" "$HOME/.config/vesktop/themes/palettedesk.theme.css" ;;
    spicetify) add spicetify "$T/spicetify-color.ini" "$HOME/.config/spicetify/Themes/palettedesk/color.ini" ;;
    gtk)       command -v gsettings >/dev/null && gsettings set org.gnome.desktop.interface color-scheme prefer-dark ;;
  esac
done
mapfile -t opt < <(python3 -I "$(dirname "$0")/matugen-opts.py" 2>/dev/null || printf 'dark\n0.00\n\n0\n')
if grep -q '^\[templates' "$cfg"; then
  if [ -n "${opt[2]:-}" ]; then matugen color hex "${opt[2]}" --config "$cfg" --mode "${opt[0]:-dark}" --type "$scheme" --contrast "${opt[1]:-0.00}" >/dev/null
  else matugen image "$img" --config "$cfg" --mode "${opt[0]:-dark}" --type "$scheme" --contrast "${opt[1]:-0.00}" --source-color-index "${opt[3]:-0}" >/dev/null \
    || matugen image "$img" --config "$cfg" --mode "${opt[0]:-dark}" --type "$scheme" --contrast "${opt[1]:-0.00}" --source-color-index 0 >/dev/null; fi
fi
# Spicetify also gets a blurred copy of the wallpaper as its backdrop (slow: runs in the background).
case " $enabled " in *" spicetify "*) command -v spicetify >/dev/null && setsid "$(dirname "$0")/spicetify-wallpaper.sh" "$img" >/dev/null 2>&1 & ;; esac
exit 0
