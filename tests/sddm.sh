#!/usr/bin/env bash
# SDDM theme + privileged helper test. Run INSIDE the Arch test VM (needs sudo, sddm, ffmpeg). It installs the theme system-wide
# in the VM, so never run it on your own machine. Checks: install, sync, helper input hardening, greeter loads the theme, uninstall.
set -u
pass=0; fail=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  \033[31mFAIL\033[0m %s (%s)\n' "$1" "$2"; fail=$((fail + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "wanted $3, got $2"; fi; }
REPO="${1:-$HOME/palettedesk-shell}"; H=/usr/libexec/palettedesk-sddm-helper; T=/usr/share/sddm/themes/palettedesk
send() { printf "$@" | sudo "$H" 2>&1; echo "rc=$?"; }
COL='#112233 #ddeeff #aabbcc #001122 #223344'

echo "install"
python3 "$REPO/scripts/palettedesk" sddm install --repo "$REPO" >/dev/null 2>&1
check "theme files installed" "$(ls "$T" | tr '\n' ' ')" "Main.qml metadata.desktop theme.conf "
check "helper is root-owned and executable" "$(stat -c '%U %a' "$H")" "root 755"
check "active theme is set" "$(cat /etc/sddm.conf.d/palettedesk.conf | tr '\n' ' ')" "[Theme] Current=palettedesk "

echo "helper accepts a valid message"
send "PDSDDM1\n$COL\n0\n" | tail -1 | grep -q 'rc=0' && ok "colours only" || bad "colours only" "rejected"
check "theme.conf.user has the colours" "$(grep -c '^primary=#aabbcc' $T/theme.conf.user)" "1"
printf '\xff\xd8\xff\xe0fakejpegdata' > "$HOME/j.bin"; n=$(stat -c %s "$HOME/j.bin")
{ printf 'PDSDDM1\n%s\n%s\n' "$COL" "$n"; cat "$HOME/j.bin"; } | sudo "$H" 2>&1; check "colours + image" "$?" "0"
check "background.jpg written and referenced" "$(test -f $T/background.jpg && grep -c 'background=background.jpg' $T/theme.conf.user)" "1"

echo "helper rejects bad input (and leaves files alone)"
before="$(sudo sha256sum $T/theme.conf.user $T/background.jpg | sha256sum)"
rej() { local label="$1"; shift; local out; out="$(printf "$@" | sudo "$H" 2>&1)"; local rc=$?; [ $rc -ne 0 ] && ok "$label" || bad "$label" "accepted: $out"; }
rej "wrong header"            'PDSDDX1\n%s\n0\n' "$COL"
rej "colour with shell chars" 'PDSDDM1\n#112233 #$(id) #aabbcc #001122 #223344\n0\n'
rej "newline injection"       'PDSDDM1\n#112233 #ddeeff #aabbcc #001122 #223344\nbackground=/etc/shadow\n0\n'
rej "four colours"            'PDSDDM1\n#112233 #ddeeff #aabbcc #001122\n0\n'
rej "short hex"               'PDSDDM1\n#123 #ddeeff #aabbcc #001122 #223344\n0\n'
rej "image over the limit"    'PDSDDM1\n%s\n2000001\n' "$COL"
rej "length longer than data" 'PDSDDM1\n%s\n50\nabc' "$COL"
rej "negative length"         'PDSDDM1\n%s\n-1\n' "$COL"
rej "not a JPEG"              'PDSDDM1\n%s\n4\nabcd' "$COL"
out="$(sudo "$H" /etc/shadow </dev/null 2>&1)"; [ $? -ne 0 ] && ok "arguments are refused" || bad "arguments are refused" "$out"
check "nothing changed after rejected input" "$(sudo sha256sum $T/theme.conf.user $T/background.jpg | sha256sum)" "$before"

echo "symlinks are not followed"
sudo ln -sf /etc/passwd "$T/.pd-theme.conf.user.tmp"; cp /etc/passwd "$HOME/passwd.before"
send "PDSDDM1\n$COL\n0\n" | tail -1 | grep -q 'rc=0' && ok "stale symlink in the way is replaced, not followed" || bad "symlink" "failed"
check "/etc/passwd untouched" "$(cmp -s /etc/passwd "$HOME/passwd.before" && echo same)" "same"
sudo rm -f "$T/theme.conf.user"; sudo ln -s /etc/os-release "$T/theme.conf.user"
send "PDSDDM1\n$COL\n0\n" >/dev/null
check "a symlinked target is replaced, /etc/os-release untouched" "$(grep -c surface= /etc/os-release) $(test -L $T/theme.conf.user && echo link || echo file)" "0 file"

echo "greeter"
# SDDM shows a theme's QML errors on screen only (not on stderr), so this can't be asserted from a log: it launches the greeter
# in test mode and leaves a screenshot at ~/greeter.png to look at.
if command -v sddm-greeter-qt6 >/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
  setsid sddm-greeter-qt6 --test-mode --theme "$T" >/dev/null 2>&1 & sleep 6; grim "$HOME/greeter.png"; pkill -f sddm-greeter
  echo "  screenshot: ~/greeter.png (a red 'cannot be loaded' message there means the theme is broken)"
else echo "  (greeter check skipped: sddm-greeter-qt6 or a Wayland session missing)"; fi

echo "uninstall"
python3 "$REPO/scripts/palettedesk" sddm uninstall >/dev/null 2>&1
left=0; for f in "$T" "$H" /etc/sddm.conf.d/palettedesk.conf /usr/share/polkit-1/actions/org.palettedesk.sddm.policy; do [ -e "$f" ] && left=$((left + 1)); done
check "everything removed" "$left" "0"
echo; echo "$pass passed, $fail failed"; [ "$fail" = 0 ]
