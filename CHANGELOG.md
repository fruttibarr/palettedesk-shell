# Changelog

All notable changes to PaletteDesk Shell. Format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Black level** slider on the Color & Display page: crush dark tones to pure black (an OLED look) or lift them.
- **Black light** strength slider on the Color & Display page: a UV-lamp look with violet shadows and glowing neon colours.
- **Color & Display** settings page: brightness, contrast, saturation, vibrance, gamma, hue shift and red/green/blue balance for the whole screen, live.
  Combines with the special effects (grayscale, sepia, CRT...). Night light and the effect picker moved here from Behavior and Blur.
- **Bar vibrancy** slider (Bar page): tints the top bar toward the wallpaper's accent colour. Saved with themes.
- **Optional SDDM login theme** (`palettedesk sddm install|sync|uninstall|status`): a login screen with your colours and a blurred copy of your wallpaper.
  Colours reach it through a tiny root helper run via pkexec that takes no file paths, validates a fixed-format message and never decodes the image.
  Recovery from a TTY: `sudo palettedesk sddm uninstall`.
- **Theme packs** (`.pdtheme`): export a theme from the Themes page (or `qs ipc call themes exportTheme`) and import others'. Packs carry only
  visual settings, validated one by one; keybinds, commands and window rules are rejected. A wallpaper is included only if you state you have the right to share it.
- **Theme other apps** (opt-in, off by default): btop, VS Code, Vesktop, spicetify colour files and a GTK dark-mode switch, regenerated with each wallpaper change.
- **Alt-Tab window switcher** (`ALT+Tab` / `ALT+SHIFT+Tab`, most recently used first; release Alt or press Enter to switch, Esc to cancel)
  and a **workspace overview** (`SUPER+Tab`) listing every workspace with its windows. IPC: `switcher next|prev|commit|cancel|status`, `overview toggle`.
- **Settings > Window rules**: per-app rules (float, pin, no blur, no focus on open, open on a workspace, opacity, size) with a
  one-click "rule for an open app", workspace rules (monitor, default, persistent) and autostart commands. Rules never stack
  when settings are re-applied, and autostart only runs at Hyprland's own startup.
- **Dashboard** (click the clock, or `qs ipc call dashboard toggle`): month calendar, weather and timers. Weather is off by default,
  uses Open-Meteo with a location you enter yourself (Settings > Behavior > Weather) and nothing is guessed from your IP.
  Timers (5/10/25/45/60 min presets, Pomodoro) survive restarts and notify when done: `qs ipc call timer start 25 Pomodoro`.
- **Screen utilities** (optional packages): color picker (`SUPER+SHIFT+C`, hyprpicker), copy text from the screen
  (`SUPER+SHIFT+O`, tesseract) and annotate a screenshot (`ALT+Print`, satty).
- **Full-screen effects** (Settings > Blur > Screen effect, `qs ipc call shader set|off|cycle|list`): Grayscale, Sepia, Vibrant, Retro CRT,
  Invert and a red-green color-blind aid, as Hyprland screen shaders in `~/.config/hypr/shaders`.
- **Keyboard layout chip** (bar module `kbd`, shown when several layouts are set): live layout name, click to switch.
- **VPN tile** in the control center for NetworkManager VPN/WireGuard profiles; `qs ipc call vpn toggle|status`.
- **Battery health** (health % of design capacity, cycles, power draw, time left) in the system monitor.
- **System monitor** (click the CPU/RAM chip in the bar, or `qs ipc call sysmon toggle`): live CPU graph with per-core bars,
  memory, GPU (AMD), network, disks, temperatures and the busiest processes. The sampler only runs while it is open.
- **Night light** (control center tile, Settings > Behavior, `qs ipc call nightlight on|off|toggle|temp N`) using `hyprsunset`,
  which is now a required package on Arch and NixOS.
- **Audio mixer** (control center button, or `qs ipc call mixer toggle`): output and input devices, master and microphone
  volume, and a volume + mute for every app that is playing or recording. `mixer micToggle` and `mixer sinkNext` for keybinds.
- **Per-monitor wallpapers**: pick a monitor in the wallpaper picker (or `set-wallpaper.sh --monitor NAME FILE`). Colours
  stay tied to the global wallpaper. `--all FILE` sets one wallpaper everywhere again.
- **Settings > Displays**: per-monitor resolution and refresh rate, position, scale, rotation and on/off. Changes apply
  live and revert after 15 seconds unless you press Keep. Stored in the `monitors` setting.
- `tests/multimonitor.sh`: regression test for popups, notifications, OSD, workspace buttons and the lock screen on two monitors.
- `tests/soak.sh`: cycles wallpapers and popups while sampling the shell's memory. A 100-iteration run (images,
  GIFs, MP4, WebM, 300 popup toggles) showed no leak: memory, threads and file handles stayed flat after warm-up.
- Shell watchdog (`qs-watchdog.sh`, started with Hyprland): warns with a notification and a **Restart shell**
  button when the shell's memory gets very high (default 1500 MB; Settings > Behavior > Shell health; 0 = off).
  It never restarts anything by itself.
- `palettedesk` command (installed to `~/.local/bin`): `version`, `doctor`, `update`, `uninstall`, `restore`, `mem`.
  `install.sh` now records a manifest, so `palettedesk uninstall` removes exactly what was installed, keeps files
  you edited, restores your previous config and leaves your home directory as it was (`--purge` also removes settings).
- `tests/lint-settings.py`: static checks that settings, theme keys, Hyprland mappings and IPC targets stay in sync.
- `tests/vm/arch-vm.sh`: a disposable Arch VM (QEMU/KVM) for end-to-end testing.
- GitHub Actions CI: lint, shellcheck, Lua/Python syntax, an Arch install test and a NixOS evaluation.
- `qs ipc call shell wallState`: reports, per screen, whether the wallpaper is animating and why not
  (playing flag, cached fullscreen state, lock state, wallpaper kind and readiness).

### Fixed
- The installer no longer needs `diff`: on minimal systems every re-run used to reinstall and back up everything. `palettedesk` no longer
  crashes when `git` is missing. The Mixer now reads the real default output.
- **Wallpaper animation and the OSD froze after any lock/unlock.** The shell kept believing the session was locked
  after unlocking (`Globals.locked` stayed true), which pauses animated wallpapers, the OSD and the audio visualizer
  until the shell is restarted. Locking and unlocking now set the flag explicitly.
- Multi-monitor: each bar shows its own monitor's workspaces and window title (they mirrored the focused monitor);
  clicking a workspace acts on that bar's monitor; popups open on the screen of the bar you clicked (or the focused
  monitor) and stay there while open; notifications and the OSD appear on the focused monitor.
- The watchdog's restart no longer leaves a duplicate shell behind.

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
