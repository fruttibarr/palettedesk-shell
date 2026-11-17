#!/bin/sh
# One-time setup so the shell can send virtual mouse clicks (used by
# "Middle click acts as right click" in Settings > Input).
#   - installs ydotool
#   - lets the logged-in user use /dev/uinput (udev "uaccess", no group/relogin needed)
#   - loads the uinput module now and at boot
# Run as root:  pkexec ~/.config/quickshell/scripts/setup-ydotool.sh
set -e
[ "$(id -u)" = 0 ] || { echo "run with pkexec or sudo" >&2; exit 1; }

pacman -S --needed --noconfirm ydotool

echo uinput > /etc/modules-load.d/uinput.conf
cat > /etc/udev/rules.d/80-uinput-uaccess.rules <<'RULE'
# let the active desktop user create virtual input devices (ydotool)
KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
RULE
modprobe uinput
udevadm control --reload-rules
udevadm trigger --name-match=uinput --action=add
