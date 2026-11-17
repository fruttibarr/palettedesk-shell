#!/usr/bin/env bash
# Warns when the shell's memory use gets very high, with a "Restart shell" button.
# It never restarts anything by itself: you decide. Started from hyprland.lua.
#
# Setting (Settings > Behavior, or ~/.config/rice/settings.json):
#   watchdogRssMb   warn above this many MB (default 1500; 0 turns the watchdog off)
# Environment (for testing): PD_WATCHDOG_INTERVAL=seconds between checks (default 60)
#   qs-watchdog.sh --restart-now   restart the shell immediately (what the button runs)
set -u

restart_shell() {
  # `qs kill` stops one instance per call: repeat until none is left, so the restart never leaves a duplicate bar behind
  for _ in 1 2 3 4 5 6 7 8; do qs kill >/dev/null 2>&1 || break; sleep 0.3; done
  sleep 1
  setsid qs >/dev/null 2>&1 < /dev/null &
}

if [ "${1:-}" = "--restart-now" ]; then restart_shell; exit 0; fi

# one watchdog per session
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/palettedesk-watchdog.lock"
flock -n 9 || exit 0

settings="$HOME/.config/rice/settings.json"
interval="${PD_WATCHDOG_INTERVAL:-60}"
declare -A warned   # pid -> epoch seconds of the last warning

threshold() {
  python3 -c '
import json, sys
try: print(int(json.load(open(sys.argv[1])).get("watchdogRssMb", 1500)))
except Exception: print(1500)' "$settings" 2>/dev/null || echo 1500
}

shell_pid() {   # the process is called qs, quickshell, or (on NixOS) .quickshell-wrapped, truncated to 15 chars
  pgrep -x qs || pgrep -x quickshell || pgrep -x .quickshell-wra
}

while sleep "$interval"; do
  limit="$(threshold)"
  [ "$limit" -gt 0 ] 2>/dev/null || continue
  pid="$(shell_pid | head -1)"; [ -n "$pid" ] || continue
  rss="$(awk '/^Rss:/ {print int($2/1024)}' "/proc/$pid/smaps_rollup" 2>/dev/null)"; [ -n "$rss" ] || continue
  [ "$rss" -gt "$limit" ] || { unset 'warned[$pid]'; continue; }
  now="$(date +%s)"
  last="${warned[$pid]:-0}"
  [ $((now - last)) -ge 21600 ] || continue   # at most one warning per 6 hours per shell process
  warned[$pid]="$now"
  (
    choice="$(notify-send -a "PaletteDesk" -u critical -t 0 \
      -A restart="Restart shell" -A later="Not now" \
      "The shell is using ${rss} MB" \
      "That is above your ${limit} MB limit. Restarting it frees the memory and takes about a second. Nothing else is affected.")"
    [ "$choice" = restart ] && restart_shell
  ) &
done
