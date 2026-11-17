#!/usr/bin/env bash
# Multi-monitor regression test. Run it INSIDE a graphical session (the test VM: tests/vm/arch-vm.sh sh ...).
# It creates a second, virtual monitor (HEADLESS-N) and checks that popups, notifications, the OSD and the
# workspace buttons use the right screen. Needs: hyprctl, qs, notify-send, wpctl, ydotool (+ ydotoold running
# with YDOTOOL_SOCKET set) for the click tests; click tests are skipped without it.
#
#   tests/multimonitor.sh            exit status 1 if any check fails
set -u
pass=0; fail=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s (%s)\n' "$1" "$2"; fail=$((fail + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "wanted $3, got $2"; fi; }

on_screen() {   # which monitor shows the layer with this namespace ("none" if nowhere)
  hyprctl layers -j | python3 -c "
import json, sys
out = [m for m, v in json.load(sys.stdin).items() for lv in v['levels'].values() for l in lv if l['namespace'] == '$1']
print(','.join(out) or 'none')"
}
focus() { hyprctl dispatch "hl.dsp.focus({ monitor = \"$1\" })" >/dev/null; sleep 1.5; }
toggle() { timeout 10 qs ipc call "$1" toggle >/dev/null 2>&1; sleep 2; }
wait_none() { for _ in $(seq 1 20); do [ "$(on_screen "$1")" = none ] && return; sleep 1; done; }
ws_of() { hyprctl monitors -j | python3 -c "
import json, sys
print([m['activeWorkspace']['id'] for m in json.load(sys.stdin) if m['name'] == '$1'][0])"; }

# a second monitor to test with
mons() { hyprctl monitors -j | python3 -c "import json,sys;print(' '.join(m['name'] for m in json.load(sys.stdin)))"; }
read -ra M <<<"$(mons)"
if [ "${#M[@]}" -lt 2 ]; then hyprctl output create headless >/dev/null 2>&1; sleep 3; read -ra M <<<"$(mons)"; fi
[ "${#M[@]}" -ge 2 ] || { echo "could not get a second monitor"; exit 2; }
A="${M[0]}"; B="${M[1]}"
echo "monitors: $A and $B"
# the memory watchdog posts a never-expiring warning if the shell is big, which would pin the toast window
timeout 10 qs ipc call settings set watchdogRssMb 0 >/dev/null 2>&1; pkill -x notify-send; sleep 1

# start from a known state: unlocked, nothing open
echo "popups (control center)"
[ "$(on_screen rice-control-center)" != none ] && toggle controlcenter
focus "$A"; toggle controlcenter;  check "no request: opens on the focused monitor ($A)" "$(on_screen rice-control-center)" "$A"
toggle controlcenter
focus "$B"; toggle controlcenter;  check "no request: opens on the focused monitor ($B)" "$(on_screen rice-control-center)" "$B"
focus "$A"; check "stays on $B when focus moves to $A (does not jump)" "$(on_screen rice-control-center)" "$B"
toggle controlcenter
focus "$A"; timeout 10 qs ipc call shell popupOn "$B" >/dev/null 2>&1; toggle controlcenter
check "announced for $B while $A has focus: opens on $B" "$(on_screen rice-control-center)" "$B"
toggle controlcenter

echo "notifications"
for m in "$A" "$B"; do
  wait_none rice-notifications; focus "$m"
  notify-send -a mmtest "Multi-monitor test" "focus on $m" -t 3000 >/dev/null 2>&1 &
  sleep 1.5; check "toast appears on the focused monitor ($m)" "$(on_screen rice-notifications)" "$m"
done

echo "volume OSD"
for m in "$A" "$B"; do
  wait_none rice-osd; focus "$m"
  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$((30 + RANDOM % 50))%" 2>/dev/null
  seen=none; for _ in $(seq 1 15); do seen="$(on_screen rice-osd)"; [ "$seen" != none ] && break; sleep 0.2; done   # it shows briefly
  check "OSD appears on the focused monitor ($m)" "$seen" "$m"
done

echo "workspace buttons on the second monitor's bar"
if [ -n "${YDOTOOL_SOCKET:-}" ] && command -v ydotool >/dev/null; then
  read -r mx my < <(hyprctl monitors -j | python3 -c "
import json, sys
m = [m for m in json.load(sys.stdin) if m['name'] == '$B'][0]
print(m['x'], m['y'])")
  focus "$A"; before_a="$(ws_of "$A")"
  # logical position of workspace button 4: 12 px bar margin + button centres 33 px apart (22 px cell + gap), y 30
  x=$(python3 -c "print(int($mx + 40 + 3 * 33))"); y=$(python3 -c "print(int($my + 30))")
  hyprctl dispatch "hl.dsp.cursor.move({ x = $x, y = $y })" >/dev/null; sleep 1; ydotool click 0xC0 >/dev/null 2>&1; sleep 2
  check "clicking a workspace on $B's bar leaves $A on its workspace" "$(ws_of "$A")" "$before_a"
  [ "$(ws_of "$B")" != "$(ws_of "$A")" ] && ok "...and switched $B" || bad "...and switched $B" "unchanged"
else
  echo "  (skipped: ydotool not available)"
fi
focus "$A"

echo "display layout (Settings > Displays writes the monitors setting; Hyprland must apply it, and a reset must undo it)"
scale_of() { hyprctl monitors -j | python3 -c "
import json, sys
print([m['scale'] for m in json.load(sys.stdin) if m['name'] == '$1'][0])"; }
setmon() { enc="$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1")"; timeout 10 qs ipc call settings set monitors "$enc" >/dev/null 2>&1; sleep 3; }
orig="$(scale_of "$B")"
setmon "{\"$B\":{\"enabled\":true,\"scale\":1.5,\"transform\":0}}"
check "scale for $B applies from the monitors setting" "$(scale_of "$B")" "1.5"
setmon '{}'
check "removing the entry resets $B to the default" "$(scale_of "$B")" "$orig"

echo "lock screen (covers every monitor; unlocking must clear the shell's locked flag)"
wall() { timeout 10 qs ipc call shell wallState 2>/dev/null | grep '^\[{' | python3 -c "
import json, sys
d = json.load(sys.stdin)[0]; print(d['$1'])"; }
timeout 10 qs ipc call lock testLock >/dev/null 2>&1; sleep 4
check "session is locked" "$(timeout 10 qs ipc call lock isLocked 2>/dev/null | tail -1)" "true"
check "wallpaper pauses while locked" "$(wall playing)" "False"
sleep 14   # the test lock unlocks itself after 15 s
check "session is unlocked again" "$(timeout 10 qs ipc call lock isLocked 2>/dev/null | tail -1)" "false"
check "shell no longer thinks it is locked (this used to stay true)" "$(wall locked)" "False"
check "wallpaper plays again after unlocking" "$(wall playing)" "True"

echo; echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
