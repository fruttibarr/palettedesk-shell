#!/usr/bin/env bash
# Soak test for the running shell: cycle wallpapers and popups while sampling the shell's memory.
# Run it inside a graphical session (the test VM, or your own desktop on a throwaway workspace).
#
#   tests/soak.sh [-n ITERATIONS] [-s SECONDS_PER_STEP] [-o out.csv] FILE [FILE...]
#
# FILE = wallpapers to cycle through (images, GIFs, videos). Output: one CSV row per iteration
# (iteration, rss_mb, pss_mb, threads, fds, kind) and a summary with the growth per iteration.
# WARNING: this changes your wallpaper and colours; set it back afterwards.
set -u
n=60; step=4; out="/tmp/soak.csv"
while getopts "n:s:o:" o; do case $o in n) n=$OPTARG ;; s) step=$OPTARG ;; o) out=$OPTARG ;; *) exit 2 ;; esac; done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { sed -n 2,9p "$0" | sed 's/^# \{0,1\}//'; exit 2; }
files=("$@")
setter="$HOME/.config/quickshell/scripts/set-wallpaper.sh"

pid() { pgrep -x qs || pgrep -x quickshell || pgrep -x .quickshell-wra; }
sample() {
  local p; p="$(pid | head -1)"; [ -n "$p" ] || return 1
  local rss pss thr fds
  rss=$(awk '/^Rss:/ {printf "%.0f", $2/1024}' "/proc/$p/smaps_rollup")
  pss=$(awk '/^Pss:/ {printf "%.0f", $2/1024}' "/proc/$p/smaps_rollup")
  thr=$(awk '/^Threads:/ {print $2}' "/proc/$p/status")
  fds=$(find "/proc/$p/fd" -mindepth 1 2>/dev/null | wc -l)
  echo "$rss,$pss,$thr,$fds"
}

echo "iteration,rss_mb,pss_mb,threads,fds,kind" > "$out"
echo "pid $(pid | head -1); $n iterations x ${step}s; files: ${#files[@]}"
for i in $(seq 1 "$n"); do
  f="${files[$(( (i - 1) % ${#files[@]} ))]}"
  case "${f,,}" in *.mp4|*.webm|*.mkv|*.mov) kind=video ;; *.gif) kind=gif ;; *) kind=image ;; esac
  "$setter" "$f" >/dev/null 2>&1
  sleep "$step"
  for t in launcher settings controlcenter; do qs ipc call "$t" toggle >/dev/null 2>&1; sleep 0.6; qs ipc call "$t" toggle >/dev/null 2>&1; sleep 0.4; done
  s="$(sample)" || { echo "the shell is gone at iteration $i"; exit 1; }
  echo "$i,$s,$kind" >> "$out"
done

python3 -I - "$out" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1])))
def col(k): return [float(r[k]) for r in rows]
n = len(rows); h = max(1, n // 4)
for k in ("rss_mb", "pss_mb", "threads", "fds"):
    v = col(k)
    first, last = sum(v[:h]) / h, sum(v[-h:]) / h
    print(f"{k:8s} first quarter avg {first:8.1f}   last quarter avg {last:8.1f}   change {last - first:+8.1f}  ({(last - first) / max(1, n - h):+.2f} per iteration)")
for kind in ("image", "gif", "video"):
    v = [float(r["rss_mb"]) for r in rows if r["kind"] == kind]
    if v: print(f"rss after a {kind:5s} wallpaper: min {min(v):.0f}  max {max(v):.0f}  MB")
PY
