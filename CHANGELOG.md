# Changelog

All notable changes to PaletteDesk Shell. Format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Shell watchdog (`qs-watchdog.sh`, started with Hyprland): warns with a notification and a **Restart shell**
  button when the shell's memory gets very high (default 900 MB; Settings > Behavior > Shell health; 0 = off).
  It never restarts anything by itself.
- `palettedesk` command (installed to `~/.local/bin`): `version`, `doctor`, `update`, `uninstall`, `restore`, `mem`.
  `install.sh` now records a manifest, so `palettedesk uninstall` removes exactly what was installed, keeps files
  you edited, restores your previous config and leaves your home directory as it was (`--purge` also removes settings).
- `tests/lint-settings.py`: static checks that settings, theme keys, Hyprland mappings and IPC targets stay in sync.
- `tests/vm/arch-vm.sh`: a disposable Arch VM (QEMU/KVM) for end-to-end testing.
- GitHub Actions CI: lint, shellcheck, Lua/Python syntax, an Arch install test and a NixOS evaluation.
- `qs ipc call shell wallState`: reports, per screen, whether the wallpaper is animating and why not
  (playing flag, cached fullscreen state, lock state, wallpaper kind and readiness).

## [0.1.0]

### Added
- Quickshell shell for Hyprland 0.57 (Lua config): bar, launcher, control center, notifications, lock
  screen, settings panel with a keybind editor, 9 built-in themes, wallpaper picker with search,
  32-band PipeWire equalizer, live lyrics, album-cover wallpapers, screen recording.
- Wallpaper-derived colours (matugen) for kitty, GTK, Qt, fish, Hyprland and (opt-in) Firefox.
- Arch installer (`install.sh`) and NixOS module + installer (`nixos/`).

### Fixed
- Video wallpapers: a QML binding loop in `VideoWall.qml` could leave a new wallpaper unrevealed.
- NixOS: Qt multimedia is provided by the module so video wallpapers play.
