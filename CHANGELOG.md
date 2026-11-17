# Changelog

All notable changes to PaletteDesk Shell. Format follows [Keep a Changelog](https://keepachangelog.com/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **9 new built-in themes:** Shinigami (Death Note: blood red, bar at the bottom), Backrooms, Poolrooms, Dreamcore, Midnight Seance, and the classic palettes Tokyo Night, Dracula, Solarized Dark and Kanagawa. `scripts/fetch-wallpapers.sh` now also downloads their wallpapers (from GitHub and wallhaven.cc).
- **Themes → Theme options → "Let themes set a screen shader"**: off = applying or rolling a theme never changes the screen shader.
- **Random theme color**: pin the wallpaper (and so accent) hue of a rolled theme (`qs ipc call themes random <style> <color>`).
- **Color pickers** for every hex color setting (seed, tint, accent override, wallpaper tint, custom border and glow colors).
- **Drag-and-drop bar layout editor** (Settings > Bar): a mini bar with Left / Center / Right zones and a "Not in bar" tray. Drag modules to move or reorder them, click one to jump to its settings; keyboard works too (arrows, Delete).
- **Custom bar modules**: show any shell command's output as a bar chip (interval or live stream, optional JSON with icon and colour, click / right / middle / scroll actions, test button, templates). IPC: `qs ipc call custommodule list|refresh <id>`.
- **Hot corners** (Settings > Behavior): run an action (overview, launcher, control center, dashboard, scratchpad, lock, your own command...) by resting the pointer in a screen corner; delay, size and fullscreen behaviour are configurable.
- **Keybind cheatsheet** (SUPER + /, `qs ipc call cheatsheet toggle`): every shortcut with your current combos, filterable.
- **Desktop widgets** (Settings > Desktop widgets): clock, calendar, now playing, CPU & RAM, weather, note, lyrics and command output on the wallpaper. Edit mode (`qs ipc call desktop edit`) to drag and resize; glass / outline / plain styles. IPC: `desktop edit|add <type>|list|clear`.
- **Automation** (Settings > Automation): rules that change settings, theme, power profile or Do Not Disturb while a condition holds (on battery, fullscreen window, app focused, time of day, extra monitor) and restore them afterwards; your own changes made meanwhile are kept. IPC: `profiles list|active|enable|disable|simulate`.

- **Random theme** button (Settings > Themes, or `qs ipc call themes random [glass|neon|soft|minimal|brutal|synth]`): rolls a designed look,
  not random settings. A style fixes combinations known to work together; one corner radius drives every radius; opacities keep a readable
  floor; always dark; the wallpaper is picked by brightness and saturation to suit the style. The look from before the first roll is kept as "Previous look".
- **~125 new visual options.** Bar: chip effects (glass, gradient, neon, underline, soft, bracket), glow, rainbow/gradient accents, bar edge lines,
  dividers, gradient/fade fills, dock flares, five workspace indicators, stacked/kanji/fuzzy clock, battery/stats/tray styles, density.
  Popups & Panels (new page): panel borders/glow/gloss/shadow, popup entrances, sidebar/card/toggle/slider/segment styles, control-center tiles, notifications, OSD.
  Global: gradient/triad window borders, shadow and glow colour modes, group tabs, blur extras, animation curve presets, light/dark mode and contrast,
  seed colour, shell palette tone and accent, wallpaper blur/vignette/grain, five new screen shaders (bloom, aberration, duotone, posterize, pixelate).
- **10 new built-in themes:** Neon Cyberpunk, Glass Aurora, Paper Light, Terminal Mono, Sakura Zen, Synthwave Sunset, Brutalist, Deep Ocean, Retro CRT, Minimal Dock.
- Settings sidebar: aligned icons, a "more pages below" hint, and soft edges on long lyric lines.

### Fixed
- Repeated identical notifications (same app, title and body) replace the earlier one instead of stacking.
- Wallpaper theming for Spicetify no longer launches Spotify when it is closed.
- A theme's colour mode, seed and contrast applied one theme late; the wallpaper step now waits until settings are saved.
- Binding loop in `IconLabel`.

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
