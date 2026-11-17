#!/usr/bin/env bash
# Installer for PaletteDesk Shell on NixOS.
#
#   ./nixos/install-nixos.sh [--dry-run] [--yes] [--wallpapers] [--firefox] [--profile] [--help]
#
# NixOS is declarative, so the system part (Hyprland session, PipeWire, fonts, packages) lives in
# nixos/module.nix: import it in your configuration and rebuild first. This script then does the
# per-user part: it checks that part is in place, copies the config into ~/.config (with backups),
# generates the colors and the equalizer config. It never edits /etc/nixos.
#
#   --profile   no module? install the user-level packages with `nix profile install` instead
#               (you still need Hyprland, PipeWire etc. from your system configuration)
# Other options are passed to install.sh (see ./install.sh --help).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE=0; PASS=()
for a in "$@"; do
  case "$a" in
    --profile) PROFILE=1 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dry-run|--yes|-y|--wallpapers|--firefox) PASS+=("$a") ;;
    *) echo "unknown option: $a (try --help)" >&2; exit 2 ;;
  esac
done
say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" != 0 ] || die "don't run this as root"
[ -e /etc/NIXOS ] || die "this is the NixOS installer; on Arch use ./install.sh"
DRY=0; for a in "${PASS[@]:-}"; do [ "$a" = "--dry-run" ] && DRY=1; done

# command -> nixpkgs attribute (what the rice calls, and where it comes from)
declare -A PKG=(
  [qs]=quickshell [matugen]=matugen [cava]=cava [cliphist]=cliphist [wl-copy]=wl-clipboard
  [grim]=grim [slurp]=slurp [wf-recorder]=wf-recorder [ffmpeg]=ffmpeg [kitty]=kitty [fish]=fish
  [thunar]=xfce.thunar [qt6ct]=qt6Packages.qt6ct [notify-send]=libnotify [python3]=python3 [git]=git [curl]=curl
)
missing=(); for c in "${!PKG[@]}"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done

if [ ${#missing[@]} -gt 0 ]; then
  say "missing commands: ${missing[*]}"
  if [ "$PROFILE" = 1 ]; then
    attrs=(); for c in "${missing[@]}"; do attrs+=("nixpkgs#${PKG[$c]}"); done
    say "installing into your user profile: ${attrs[*]}"
    if [ "$DRY" = 1 ]; then echo "   [dry-run] nix profile add ${attrs[*]}"
    else
      nixcmd=(nix --extra-experimental-features 'nix-command flakes' profile)
      # newer Nix renamed `profile install` to `profile add`; try the new name first
      "${nixcmd[@]}" add "${attrs[@]}" 2>/dev/null || "${nixcmd[@]}" install "${attrs[@]}"
    fi
  else
    cat >&2 <<MSG

These come from the system module. Add this to your NixOS configuration, then rebuild and log in again:

    imports = [ $SRC/nixos/module.nix ];

(or re-run with --profile to install just the user-level packages with 'nix profile install')
MSG
    exit 1
  fi
fi

# system pieces that a user-level install can't provide (warn only)
command -v start-hyprland >/dev/null 2>&1 || warn "Hyprland is not installed (programs.hyprland.enable = true; see nixos/module.nix)"
command -v pw-cli >/dev/null 2>&1 || warn "PipeWire tools not found (services.pipewire.enable = true)"
# polkit is started on demand over D-Bus, so check that it is installed, not that it is running
[ -e /etc/systemd/system/polkit.service ] || warn "polkit is not enabled (security.polkit.enable = true)"
fonts="$(fc-list 2>/dev/null || true)"   # (not piped into grep -q: SIGPIPE + pipefail gives false negatives)
[[ "$fonts" == *"JetBrainsMono Nerd"* ]] || warn "JetBrainsMono Nerd Font not found (fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ])"

say "running the config installer"
exec "$SRC/install.sh" --no-packages "${PASS[@]}"
