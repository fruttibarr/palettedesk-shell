#!/usr/bin/env bash
# Window management regression test. Run INSIDE a graphical session (the test VM): window rules, workspace rules,
# autostart wiring, the Alt-Tab switcher (API and real key path) and the overview.
#   tests/windows.sh     exit status 1 if any check fails.   Needs ydotool + ydotoold (YDOTOOL_SOCKET) for the key checks.
set -u
pass=0; fail=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  \033[31mFAIL\033[0m %s (%s)\n' "$1" "$2"; fail=$((fail + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "wanted $3, got $2"; fi; }
q() { timeout 10 qs ipc call "$@" 2>&1 | grep -v 'WARN\|Qt depends\|If this causes\|for more information'; }
setj() { local enc; enc="$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$2")"; q settings set "$1" "$enc" >/dev/null; sleep 3; }
floating() { hyprctl clients -j | python3 -c "import json,sys;print([c['floating'] for c in json.load(sys.stdin) if c['title']=='$1'][0])"; }
active() { hyprctl activewindow -j | python3 -c "import json,sys;print(json.load(sys.stdin).get('title'))"; }
open_win() { setsid kitty --title "$1" sh -c 'sleep 600' >/dev/null 2>&1 & sleep 2.5; }
cleanup() { pkill -f 'title wt-' 2>/dev/null; setj windowRules '[]'; setj workspaceRules '[]'; setj autostart '[]'; }
trap cleanup EXIT
pkill -f 'title wt-' 2>/dev/null; sleep 1

echo "window rules"
setj windowRules '[{"enabled":true,"class":"^kitty$","float":true}]'
open_win wt-1; check "a matching rule floats a new window" "$(floating wt-1)" "True"
setj windowRules '[{"enabled":false,"class":"^kitty$","float":true}]'
open_win wt-2; check "a disabled rule no longer applies" "$(floating wt-2)" "False"
setj windowRules '[{"enabled":true,"class":"^kitty$","float":true}]'
for i in 1 2 3 4 5 6; do q settings set blurSize $((6 + i % 3)) >/dev/null; sleep 0.3; done; sleep 2
open_win wt-3; check "rules still work after repeated re-applies (no stacking)" "$(floating wt-3)" "True"
setj windowRules '[{"enabled":true,"class":"","float":true}]'
check "a rule with no class/title is ignored" "$(grep -c 'hl.window_rule({ name = "rice-win' "$HOME/.config/hypr/rice-settings.lua")" "0"
setj windowRules '[]'; pkill -f 'title wt-' 2>/dev/null; sleep 1

echo "workspace rules and autostart (generated Lua)"
setj workspaceRules '[{"workspace":"5","persistent":true}]'
check "workspace rule is generated" "$(grep -c 'hl.workspace_rule({ workspace = "5", persistent = true })' "$HOME/.config/hypr/rice-settings.lua")" "1"
setj autostart '["touch /tmp/wt-autostart"]'; rm -f /tmp/wt-autostart; q settings set blurSize 8 >/dev/null; sleep 3
check "autostart does not run on a live settings change" "$(test -e /tmp/wt-autostart && echo ran || echo no)" "no"
check "autostart command is in the generated Lua" "$(grep -c 'touch /tmp/wt-autostart' "$HOME/.config/hypr/rice-settings.lua")" "1"

echo "switcher and overview"
for n in wt-A wt-B wt-C; do open_win "$n"; done
check "newest window is focused" "$(active)" "wt-C"
q switcher next >/dev/null; sleep 1
check "switcher opens on 'next'" "$(q switcher status | cut -c1-6)" "open 2"
q switcher commit >/dev/null; sleep 1.5
check "commit focuses the previously used window" "$(active)" "wt-B"
if [ -n "${YDOTOOL_SOCKET:-}" ] && command -v ydotool >/dev/null; then
  ydotool key 56:1 15:1 15:0 >/dev/null 2>&1; sleep 1.5
  check "Alt+Tab opens the switcher" "$(q switcher status | cut -c1-4)" "open"
  ydotool key 56:0 >/dev/null 2>&1; sleep 1.5
  check "releasing Alt switches window" "$(active)" "wt-C"
  q switcher next >/dev/null; sleep 1; ydotool key 1:1 1:0 >/dev/null 2>&1; sleep 1.2
  check "Escape cancels" "$(q switcher status | cut -c1-6)" "closed"
else echo "  (key checks skipped: ydotool not available)"; fi
q overview toggle >/dev/null; sleep 2
check "overview opens" "$(hyprctl layers -j | python3 -c "import json,sys;print(any(l['namespace']=='rice-overview' for v in json.load(sys.stdin).values() for lv in v['levels'].values() for l in lv))")" "True"
q overview toggle >/dev/null

echo; echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
