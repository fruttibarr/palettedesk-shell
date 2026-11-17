#!/usr/bin/env bash
# Screen recorder (wf-recorder). Settings come from ~/.config/rice/settings.json (rec* keys).
# Usage: screenrec.sh start [region|full|window] | stop | toggle [mode] | status
#   status prints "idle" or "recording <start-epoch> <file>"
set -uo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/rice-rec"      # file: line1 pid, line2 start epoch, line3 output file
cfgfile="$HOME/.config/rice/settings.json"

cfg() {   # cfg key default
  python3 -I - "$cfgfile" "$1" "$2" <<'EOF'
import json, sys
try: v = json.load(open(sys.argv[1])).get(sys.argv[2], sys.argv[3])
except Exception: v = sys.argv[3]
print(str(v).lower() if isinstance(v, bool) else v)
EOF
}

running() {
  [[ -f $state ]] || return 1
  local pid; pid=$(sed -n 1p "$state")
  [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null && [[ $(cat "/proc/$pid/comm" 2>/dev/null) == wf-recorder ]]
}

notify() { [[ $(cfg recNotify true) == true ]] && notify-send -a "Screen recorder" "$@" || true; }

do_status() {
  if running; then echo "recording $(sed -n 2p "$state") $(sed -n 3p "$state")"; else echo idle; fi
}

do_start() {
  running && exit 0
  command -v wf-recorder >/dev/null || { notify-send -a "Screen recorder" -u critical "wf-recorder is not installed" "Install it:  sudo pacman -S wf-recorder"; exit 1; }

  local mode="${1:-$(cfg recMode region)}"
  local fmt fps quality enc audio dir countdown
  fmt=$(cfg recFormat mp4); fps=$(cfg recFps 30); quality=$(cfg recQuality medium)
  enc=$(cfg recEncoder software); audio=$(cfg recAudio none); countdown=$(cfg recCountdown 3)
  dir=$(cfg recDir "$HOME/Videos/Recordings"); dir="${dir/#\~/$HOME}"
  mkdir -p "$dir"
  local file
  file="$dir/$(date +%Y-%m-%d_%H-%M-%S).$fmt"

  # what to record
  local args=()
  case "$mode" in
    region)
      local accent
      accent=$(python3 -I -c 'import json,os;print(json.load(open(os.path.expanduser("~/.local/state/rice/colors.json")))["primary"])' 2>/dev/null || echo "#cebdfe")
      local geom; geom=$(slurp -d -b '#00000066' -c "${accent}ff" -s '#00000000' -w 2) || exit 0   # Esc = cancel
      args+=(-g "$geom") ;;
    window)
      local geom; geom=$(hyprctl activewindow -j | python3 -I -c 'import json,sys;w=json.load(sys.stdin);print(f"{w[\"at\"][0]},{w[\"at\"][1]} {w[\"size\"][0]}x{w[\"size\"][1]}")') || exit 1
      args+=(-g "$geom") ;;
    full)
      local out; out=$(hyprctl monitors -j | python3 -I -c 'import json,sys;m=[m for m in json.load(sys.stdin) if m.get("focused")];print(m[0]["name"] if m else "")')
      [[ -n $out ]] && args+=(-o "$out") ;;
    *) echo "unknown mode: $mode" >&2; exit 1 ;;
  esac

  # encoder
  local crf qp
  case "$quality" in low) crf=29; qp=32 ;; high) crf=18; qp=20 ;; *) crf=23; qp=26 ;; esac
  case "$fmt" in
    webm) args+=(-c libvpx-vp9 -p "crf=$crf" -p b=0 -p deadline=realtime -p cpu-used=8 -p row-mt=1) ;;
    *)
      if [[ $enc == hardware && -e /dev/dri/renderD128 ]]; then
        args+=(-c h264_vaapi -d /dev/dri/renderD128 -p "qp=$qp")
      else
        args+=(-c libx264 -p preset=veryfast -p "crf=$crf" -x yuv420p)
      fi ;;
  esac
  args+=(-r "$fps")

  # audio
  case "$audio" in
    system) args+=(--audio="$(pactl get-default-sink).monitor") ;;
    mic)    args+=(--audio="$(pactl get-default-source)") ;;
  esac
  if [[ $audio == system || $audio == mic ]]; then
    [[ $fmt == webm ]] && args+=(-C libopus) || args+=(-C aac)
  fi

  if (( countdown > 0 )); then
    for ((i = countdown; i > 0; i--)); do
      notify-send -a "Screen recorder" -r 4747 -t 1100 -i media-record "Recording in $i…"
      sleep 1
    done
  fi

  setsid wf-recorder "${args[@]}" -f "$file" >/dev/null 2>"${state}.log" &
  local pid=$!
  printf '%s\n%s\n%s\n' "$pid" "$(date +%s)" "$file" > "$state"
  sleep 0.6
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$state"
    notify-send -a "Screen recorder" -u critical "Recording failed to start" "$(tail -n 3 "${state}.log")"
    exit 1
  fi
  notify -r 4747 -t 2000 -i media-record "Recording started" "Stop with the bar chip or the keybind"
}

do_stop() {
  running || { rm -f "$state"; exit 0; }
  local pid file start
  pid=$(sed -n 1p "$state"); start=$(sed -n 2p "$state"); file=$(sed -n 3p "$state")
  kill -INT "$pid"
  for _ in $(seq 100); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done   # let it finalize the file
  rm -f "$state"
  [[ -s $file ]] || { notify-send -a "Screen recorder" -u critical "Recording is empty" "$(tail -n 3 "${state}.log")"; exit 1; }

  [[ $(cfg recCopyPath false) == true ]] && printf '%s' "$file" | wl-copy
  local secs=$(( $(date +%s) - start )) size; size=$(du -h "$file" | cut -f1)
  local thumb="${XDG_RUNTIME_DIR:-/tmp}/rice-rec-thumb.png"
  ffmpeg -v error -y -ss 0.3 -i "$file" -frames:v 1 -vf scale=320:-2 "$thumb" 2>/dev/null || thumb=media-record
  (
    action=$(notify-send -a "Screen recorder" -i "$thumb" -A default=Play -A folder="Show in folder" \
             "Recording saved" "$(basename "$file") · $((secs/60))m$(printf %02d $((secs%60)))s · $size" --wait || true)
    case "$action" in
      default) xdg-open "$file" ;;
      folder)  xdg-open "$(dirname "$file")" ;;
    esac
  ) >/dev/null 2>&1 &
}

case "${1:-toggle}" in
  start)  do_start "${2:-}" ;;
  stop)   do_stop ;;
  toggle) if running; then do_stop; else do_start "${2:-}"; fi ;;
  status) do_status ;;
  *) echo "usage: $0 start [region|full|window] | stop | toggle [mode] | status" >&2; exit 1 ;;
esac
