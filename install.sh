#!/usr/bin/env bash
# Installer for PaletteDesk Shell, a Hyprland + Quickshell rice (Arch and Arch-based distros).
#
#   ./install.sh [--dry-run] [--yes] [--no-packages] [--aur] [--firefox] [--wallpapers] [--help]
#
# What it does: installs packages (asks first), backs up anything it would replace,
# copies the config into ~/.config, then generates the colors and the equalizer config.
# It never runs as root, never enables services, and never touches system files.
# Re-running is safe: files that are already identical are skipped.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$STATE/rice-install/backup-$STAMP"

DRY=0; YES=0; PKGS=1; AUR=0; FIREFOX=0; WALLS_FETCH=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    --no-packages) PKGS=0 ;;
    --aur) AUR=1 ;;
    --firefox) FIREFOX=1 ;;
    --wallpapers) WALLS_FETCH=1 ;;
    -h|--help) sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a (try --help)" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
ask()  { [ "$YES" = 1 ] && return 0; [ -t 0 ] || return 1; read -r -p "$1 [y/N] " r; [[ "$r" =~ ^[Yy]$ ]]; }
NOCONFIRM=(); [ "$YES" = 1 ] && NOCONFIRM=(--noconfirm)
list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"; }

[ "$(id -u)" != 0 ] || die "don't run this as root; it asks for sudo only when installing packages"
[ -d "$SRC/config" ] || die "run this from the repository (config/ not found next to install.sh)"
[ "$DRY" = 1 ] && say "dry run: nothing will be changed"

# ---------------------------------------------------------------- packages
if [ "$PKGS" = 1 ]; then
  command -v pacman >/dev/null || die "pacman not found - this installer is for Arch-based systems (use --no-packages to skip)"
  missing=(); for p in $(list "$SRC/packages/pacman.txt"); do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
  if [ ${#missing[@]} -gt 0 ]; then
    say "missing packages: ${missing[*]}"
    if ask "install them with sudo pacman -S --needed?"; then run sudo pacman -S --needed "${NOCONFIRM[@]}" "${missing[@]}"
    else warn "skipped - the rice will not work until these are installed"; fi
  else say "all required packages are installed"; fi

  opt=(); for p in $(list "$SRC/packages/optional.txt"); do pacman -Qq "$p" >/dev/null 2>&1 || opt+=("$p"); done
  if [ ${#opt[@]} -gt 0 ] && ask "install optional packages (${opt[*]})?"; then run sudo pacman -S --needed "${NOCONFIRM[@]}" "${opt[@]}"; fi

  if [ "$AUR" = 1 ]; then
    helper=""; for h in paru yay; do command -v $h >/dev/null && { helper=$h; break; }; done
    if [ -z "$helper" ]; then warn "--aur needs yay or paru"; else
      a=(); for p in $(list "$SRC/packages/aur.txt"); do pacman -Qq "$p" >/dev/null 2>&1 || a+=("$p"); done
      [ ${#a[@]} -gt 0 ] && ask "install AUR packages (${a[*]}) with $helper? Read the PKGBUILDs first." && run $helper -S --needed "${NOCONFIRM[@]}" "${a[@]}"
    fi
  fi
  hv="$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' | sed 's/-.*//')"
  if [ -n "$hv" ] && [ "$(printf '%s\n0.57.0\n' "$hv" | sort -V | head -1)" != "0.57.0" ]; then
    warn "Hyprland $hv found; the Lua config (hyprland.lua) needs 0.57 or newer"
  fi
fi

# ---------------------------------------------------------------- files
BACKED=0
# Everything installed is listed here, then handed to `palettedesk record` so that
# `palettedesk uninstall` knows exactly what to remove (and whether you edited it since).
MANIFEST_LIST="$(mktemp)"; trap 'rm -f "$MANIFEST_LIST"' EXIT
note() { [ "$DRY" = 1 ] || printf '%s\n' "$1" >> "$MANIFEST_LIST"; }
backup() {  # move an existing path into the backup folder, keeping its path under $HOME
  local t="$1" rel="${1#"$HOME"/}"
  run mkdir -p "$BACKUP/$(dirname "$rel")"; run mv "$t" "$BACKUP/$rel"; BACKED=1
  [ "$DRY" = 1 ] || printf '%s\n' "$rel" >> "$BACKUP/.items"   # what `palettedesk restore` puts back
}
install_path() {  # install_path <source> <destination> [keep-existing]
  local s="$1" d="$2" keep="${3:-}"
  if [ -e "$d" ] || [ -L "$d" ]; then
    [ "$keep" = keep ] && { say "keeping your existing ${d/#$HOME/~}"; return; }
    if diff -rq "$s" "$d" >/dev/null 2>&1; then note "$d"; return; fi
    say "backing up ${d/#$HOME/~}"; backup "$d"
  fi
  say "installing ${d/#$HOME/~}"
  run mkdir -p "$(dirname "$d")"; run cp -a "$s" "$d"
  [ "$keep" = keep ] || note "$d"   # your settings file is yours: never recorded, never removed by uninstall
}

C="$SRC/config"
install_path "$C/quickshell"                 "$CFG/quickshell"
install_path "$C/hypr/hyprland.lua"          "$CFG/hypr/hyprland.lua"
install_path "$C/hypr/shaders"                "$CFG/hypr/shaders"   # full-screen effects (Settings > Blur)
install_path "$C/matugen/templates"          "$CFG/matugen/templates"
install_path "$C/matugen/config.toml"        "$CFG/matugen/config.toml"
install_path "$C/kitty/kitty.conf"           "$CFG/kitty/kitty.conf"
install_path "$C/fish/config.fish"           "$CFG/fish/config.fish"
install_path "$C/fish/functions/fish_prompt.fish" "$CFG/fish/functions/fish_prompt.fish"
install_path "$C/rice/settings.json"         "$CFG/rice/settings.json" keep   # your settings are never overwritten
install_path "$SRC/scripts/palettedesk"        "$HOME/.local/bin/palettedesk"   # manage the install: palettedesk --help
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "add ~/.local/bin to your PATH to use the palettedesk command" ;; esac

# qt6ct.conf needs an absolute path to the generated palette
if [ "$DRY" = 0 ]; then
  q="$(mktemp)"; sed "s#@HOME@#$HOME#g" "$C/qt6ct/qt6ct.conf.in" > "$q"
  install_path "$q" "$CFG/qt6ct/qt6ct.conf"; rm -f "$q"
else say "would install ~/.config/qt6ct/qt6ct.conf"; fi

# ---------------------------------------------------------------- Firefox (opt-in)
if [ "$FIREFOX" = 1 ]; then
  prof=""
  for d in "$CFG"/mozilla/firefox/*.default-release "$HOME"/.mozilla/firefox/*.default-release; do [ -d "$d" ] && { prof="$d"; break; }; done
  if [ -z "$prof" ]; then warn "no Firefox default-release profile found; skipping"; else
    say "Firefox profile: ${prof/#$HOME/~}"
    install_path "$C/firefox/userChrome.css"  "$prof/chrome/userChrome.css"
    install_path "$C/firefox/userContent.css" "$prof/chrome/userContent.css"
    if ! grep -q '^\[templates.firefox\]' "$CFG/matugen/config.toml" 2>/dev/null; then
      if [ "$DRY" = 0 ]; then { echo; sed "s#@FFPROFILE@#$prof#" "$C/matugen/firefox.toml.in"; } >> "$CFG/matugen/config.toml"; fi
    fi
    warn "in Firefox set toolkit.legacyUserProfileCustomizations.stylesheets = true (about:config), then restart it"
  fi
fi

# ---------------------------------------------------------------- generated files
WALLS="$HOME/Pictures/Wallpapers"
if [ "$DRY" = 0 ]; then
  mkdir -p "$WALLS" "$STATE/rice"
  if [ "$WALLS_FETCH" = 1 ] || { [ "$YES" = 0 ] && ask "download the 9 wallpapers the built-in themes use (about 37 MB, one file each from the authors' GitHub repos)?"; }; then
    "$SRC/scripts/fetch-wallpapers.sh" || warn "wallpaper download had errors (see above)"
  fi
  if [ -z "$(find -L "$WALLS" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' \) -print -quit 2>/dev/null)" ]; then
    say "no wallpapers found; making a default one (add your own, or re-run with --wallpapers)"
    mkdir -p "$WALLS/Default"
    ffmpeg -loglevel error -y -f lavfi -i "gradients=s=1920x1080:c0=0x1d2b53:c1=0x7e2553:c2=0x2a9d8f:n=3:seed=7:duration=1" \
      -frames:v 1 "$WALLS/Default/rice-default.png" && note "$WALLS/Default/rice-default.png" || warn "could not generate a default wallpaper"
  fi
  # matugen overwrites the GTK stylesheets; keep any hand-written ones
  for f in "$CFG/gtk-3.0/gtk.css" "$CFG/gtk-4.0/gtk.css"; do
    [ -f "$f" ] && ! grep -qi 'matugen\|rice' "$f" && { say "backing up ${f/#$HOME/~}"; backup "$f"; }
  done
  mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0" "$CFG/qt6ct/colors" "$CFG/fish/conf.d"
  if [ -f "$STATE/rice/colors.json" ]; then
    say "keeping your current wallpaper and colors"
  else
    # first install: start on the first built-in theme's wallpaper if we have it
    first="$WALLS/DenverCoder1-minimalistic-wallpaper-collection/images/denis-istomin-midnight-gazing.png"
    say "generating colors from a wallpaper (matugen)"
    if [ -f "$first" ]; then arg=("$first"); else arg=(); fi
    "$CFG/quickshell/scripts/set-wallpaper.sh" "${arg[@]}" >/dev/null || warn "color generation failed; run ~/.config/quickshell/scripts/set-wallpaper.sh to see why"
  fi
  say "generating the equalizer config"
  python3 -I "$CFG/quickshell/scripts/gen-eq.py" || warn "equalizer config failed (the rest still works)"
else
  say "would pick a wallpaper, run matugen and generate the equalizer config"
fi

# ---------------------------------------------------------------- manifest
if [ "$DRY" = 0 ]; then
  python3 -I "$SRC/scripts/palettedesk" record --list "$MANIFEST_LIST" --repo "$SRC" \
    --backup "$([ "$BACKED" = 1 ] && echo "$BACKUP" || true)" || warn "could not write the install manifest (palettedesk uninstall will not work)"
fi

# ---------------------------------------------------------------- notes
[ "$BACKED" = 1 ] && say "your previous files are in ${BACKUP/#$HOME/~}"
for s in NetworkManager bluetooth; do
  systemctl is-active -q "$s" 2>/dev/null || warn "$s.service is not running (Wi-Fi/Bluetooth tiles need it): sudo systemctl enable --now $s"
done
cat <<NOTE

Done. Next steps:
  1. Log out and back in, then pick the Hyprland session (or from a TTY run: start-hyprland).
     Logging in fresh also lets PipeWire load the equalizer.
  2. Optional: re-run with --wallpapers (or scripts/fetch-wallpapers.sh) for the built-in themes' wallpapers.
  3. Optional: "Middle click acts as right click" needs a one-time setup from Settings > Input.
  4. Optional: chsh -s /usr/bin/fish
NOTE
