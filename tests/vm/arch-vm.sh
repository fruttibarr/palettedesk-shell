#!/usr/bin/env bash
# Disposable Arch Linux VM for testing PaletteDesk Shell end to end (QEMU/KVM, software rendering).
#
#   tests/vm/arch-vm.sh up            download + verify the official Arch image, boot a throwaway copy
#   tests/vm/arch-vm.sh push          copy this repo into the VM (~/palettedesk-shell)
#   tests/vm/arch-vm.sh install [..]  run ./install.sh --yes [..] in the VM
#   tests/vm/arch-vm.sh hypr          log in on the VM console and start Hyprland
#   tests/vm/arch-vm.sh idle-off      stop the VM session from locking / blanking while you test
#   tests/vm/arch-vm.sh restart-shell kill every shell instance and start exactly one
#   tests/vm/arch-vm.sh sh 'cmd'      run a command inside the VM's Hyprland session (Wayland env set)
#   tests/vm/arch-vm.sh ssh 'cmd'     run a plain command in the VM
#   tests/vm/arch-vm.sh shot out.png  screenshot the VM desktop to a local file (before screen shaders/night light)
#   tests/vm/arch-vm.sh screen out.png  what the VM's display really shows, shaders included (QEMU screendump)
#   tests/vm/arch-vm.sh down | reset  power off (keep disk) | power off and delete the disk
#
# Needs: qemu-desktop, edk2-ovmf, curl, ssh. The VM user is arch/arch, reachable only on 127.0.0.1.
# State lives in $PD_VM_DIR (default ~/.cache/palettedesk-vm). Nothing here touches your real ~/.config.
set -euo pipefail

DIR="${PD_VM_DIR:-$HOME/.cache/palettedesk-vm}"
PORT="${PD_VM_PORT:-2222}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2"
OVMF_CODE="${OVMF_CODE:-/usr/share/edk2/x64/OVMF_CODE.4m.fd}"
OVMF_VARS="${OVMF_VARS:-/usr/share/edk2/x64/OVMF_VARS.4m.fd}"
mkdir -p "$DIR"

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

askpass() { printf '#!/bin/sh\necho arch\n' > "$DIR/askpass.sh"; chmod +x "$DIR/askpass.sh"; }
vmssh() {
  askpass
  SSH_ASKPASS="$DIR/askpass.sh" SSH_ASKPASS_REQUIRE=force setsid -w ssh -p "$PORT" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 \
    arch@127.0.0.1 "$@"
}
# QEMU human monitor: "sendkey ..." / "screendump ..." / "quit"
qmon() {
  python3 -I - "$DIR/mon.sock" "$@" <<'PY'
import socket, sys, time
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); s.settimeout(2)
try: s.recv(4096)
except Exception: pass
for cmd in sys.argv[2:]:
    s.sendall((cmd + "\n").encode()); time.sleep(1)
    try: s.recv(65536)
    except Exception: pass
PY
}
qtype() {  # type text on the VM console, "\n" = Enter
  python3 -I - "$DIR/mon.sock" "$1" <<'PY'
import socket, sys, time
m = {" ": "spc", "\n": "ret", "-": "minus", ".": "dot", "/": "slash", "_": "shift-minus", "=": "equal"}
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); s.settimeout(1)
try: s.recv(4096)
except Exception: pass
for ch in sys.argv[2].encode().decode("unicode_escape"):
    k = m.get(ch) or ("shift-" + ch.lower() if ch.isupper() else ch)
    s.sendall(f"sendkey {k}\n".encode()); time.sleep(0.07)
    try: s.recv(4096)
    except Exception: pass
PY
}
running() { [ -f "$DIR/qemu.pid" ] && kill -0 "$(cat "$DIR/qemu.pid")" 2>/dev/null; }
env_prefix() { echo 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1);'; }

cmd="${1:-help}"; shift || true
case "$cmd" in
  up)
    command -v qemu-system-x86_64 >/dev/null || die "qemu is not installed (sudo pacman -S qemu-desktop edk2-ovmf)"
    [ -f "$OVMF_CODE" ] || die "OVMF firmware not found at $OVMF_CODE (sudo pacman -S edk2-ovmf)"
    if ! running; then
      if [ ! -s "$DIR/base.qcow2" ]; then
        say "downloading the official Arch image (about 500 MB)"
        curl -fSL -o "$DIR/base.qcow2.part" "$BASE_URL" && curl -fsSL -o "$DIR/base.sha256" "$BASE_URL.SHA256"
        echo "$(cut -d' ' -f1 "$DIR/base.sha256")  $DIR/base.qcow2.part" | sha256sum -c - || die "checksum mismatch"
        mv "$DIR/base.qcow2.part" "$DIR/base.qcow2"
      fi
      # NB: the image is already 40 GiB. Never ask for a smaller overlay: it truncates the disk and the VM can't boot.
      [ -f "$DIR/disk.qcow2" ] || { qemu-img create -q -f qcow2 -b "$DIR/base.qcow2" -F qcow2 "$DIR/disk.qcow2"; cp "$OVMF_VARS" "$DIR/vars.fd"; }
      say "booting the VM (ssh on 127.0.0.1:$PORT)"
      rm -f "$DIR/mon.sock"
      nohup qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 6144 -machine q35 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" -drive if=pflash,format=raw,file="$DIR/vars.fd" \
        -drive file="$DIR/disk.qcow2",if=none,id=d0 -device virtio-blk-pci,drive=d0 \
        -device virtio-vga,xres=1920,yres=1080 -display none \
        -netdev user,id=n0,hostfwd=tcp:127.0.0.1:"$PORT"-:22 -device virtio-net-pci,netdev=n0 \
        -monitor unix:"$DIR/mon.sock",server,nowait -serial file:"$DIR/serial.log" -pidfile "$DIR/qemu.pid" \
        >"$DIR/qemu.out" 2>&1 &
    fi
    for _ in $(seq 1 60); do vmssh 'echo up' 2>/dev/null | grep -q up && { say "VM is up"; exit 0; }; sleep 5; done
    die "VM did not answer on ssh (see $DIR/qemu.out)" ;;
  push)
    say "copying the repo into the VM"
    tar -C "$REPO" --exclude=.git -cf - . | vmssh 'rm -rf ~/palettedesk-shell; mkdir ~/palettedesk-shell && tar -xf - -C ~/palettedesk-shell && ls ~/palettedesk-shell | head -3' ;;
  install)
    vmssh 'sudo pacman-key --init >/dev/null 2>&1; sudo pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1; cd ~/palettedesk-shell && ./install.sh --yes '"$*" ;;
  hypr)
    qtype 'arch\n'; sleep 2; qtype 'arch\n'; sleep 3; qtype 'start-hyprland\n'; sleep 30
    vmssh "$(env_prefix) hyprctl version | head -1; echo errors: \$(hyprctl configerrors | grep -c .)" ;;
  idle-off)
    vmssh "$(env_prefix) python3 - <<'PY'
import json,os
p=os.path.expanduser('~/.config/rice/settings.json'); d=json.load(open(p))
for k in ('dimAfter','lockAfter','screenOffAfter','suspendAfter'): d[k]=0
json.dump(d,open(p,'w'),indent=4)
PY
echo idle disabled" ;;
  restart-shell)
    vmssh "$(env_prefix) for _ in 1 2 3 4 5 6 7 8; do qs kill >/dev/null 2>&1 || break; sleep 0.3; done; sleep 1; setsid qs >/dev/null 2>&1 < /dev/null & sleep 12; echo shell instances: \$(pgrep -xc qs)" ;;
  sh)   vmssh "$(env_prefix) $*" ;;
  ssh)  vmssh "$@" ;;
  shot)
    out="${1:?usage: shot out.png}"
    vmssh "$(env_prefix) mkdir -p ~/s; timeout 25 grim ~/s/x.png" && vmssh 'cat ~/s/x.png' > "$out" && say "saved $out" ;;
  screen)
    out="${1:?usage: screen out.png}"; rm -f "$DIR/screen.ppm"
    qmon "screendump $DIR/screen.ppm" >/dev/null 2>&1; sleep 1
    ffmpeg -loglevel error -y -i "$DIR/screen.ppm" "$out" && say "saved $out" ;;
  down)  running && { qmon quit >/dev/null 2>&1 || true; sleep 2; }; say "VM stopped" ;;
  reset) "$0" down; rm -f "$DIR/disk.qcow2" "$DIR/vars.fd" "$DIR/qemu.pid"; say "VM disk deleted (the downloaded image is kept)" ;;
  *) sed -n 2,16p "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
esac
