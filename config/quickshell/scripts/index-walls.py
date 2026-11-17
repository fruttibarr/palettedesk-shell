#!/usr/bin/env python3
"""Color/brightness/resolution index for the wallpaper picker's smart search.

Writes ~/.cache/rice/wallindex.json:
  { path: { m: mtime, w, h, l: brightness 0-100, s: colorfulness 0-100,
            c: { colorName: percent, ... }, a: accent color name, p: ["#rrggbb", ...] (main colors) } }
Incremental: files whose mtime is unchanged are skipped. Progress goes to stdout
as "progress done total"; "saved" after each write so the picker can reload.
"""
import colorsys, hashlib, json, os, re, subprocess, sys, time
from concurrent.futures import ThreadPoolExecutor

HOME = os.path.expanduser("~")
ROOT = os.path.join(HOME, "Pictures/Wallpapers")
OUT = os.path.join(HOME, ".cache/rice/wallindex.json")
THUMBS = os.path.join(HOME, ".cache/rice/thumbs")
IMG = (".jpg", ".jpeg", ".png", ".webp", ".gif")
VID = (".mp4", ".webm", ".mkv", ".mov")
N = 24  # sample grid


def color_name(r, g, b):
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if v < 0.16:
        return "black"
    if s < 0.16 or (s < 0.25 and v < 0.35):
        return "white" if v > 0.82 else "gray"
    d = h * 360
    if d < 14 or d >= 345:
        return "red" if v > 0.3 else "brown"
    if d < 40:
        return "orange" if v > 0.6 else "brown"
    if d < 66:
        return "yellow" if v > 0.5 else "brown"
    if d < 160:
        return "green"
    if d < 195:
        return "teal"
    if d < 255:
        return "blue"
    if d < 290:
        return "purple"
    return "pink"


THUMB_W = 400


def thumb_path(path):
    """Same naming as make-thumbs.sh / Qt.md5() in WallpaperPicker.qml."""
    return os.path.join(THUMBS, hashlib.md5(path.encode()).hexdigest() + ".jpg")


def sample(path):
    """Return (w, h, raw rgb bytes of an N x N downscale) or None."""
    src, seek = path, []
    if path.lower().endswith(VID):
        thumb = os.path.join(THUMBS, hashlib.md5(path.encode()).hexdigest() + ".jpg")
        if os.path.exists(thumb):
            src = thumb
        else:
            seek = ["-ss", "1"]
    # Images: in the same decode, also write a small picker thumbnail (THUMB_W px wide)
    if path.lower().endswith(VID):
        args = ["-vf", f"scale={N}:{N}:flags=area", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    else:
        os.makedirs(THUMBS, exist_ok=True)
        args = ["-filter_complex", f"[0:v]split=2[a][b];[a]scale={N}:{N}:flags=area[s];"
                                   f"[b]scale='min({THUMB_W},iw)':-2:flags=bicubic[t]",
                "-map", "[s]", "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-",
                "-map", "[t]", "-frames:v", "1", "-q:v", "4", "-y", thumb_path(path)]
    try:
        p = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", *seek, "-i", src, "-frames:v", "1", *args],
                           capture_output=True, timeout=30)
    except Exception:
        return None
    if len(p.stdout) < N * N * 3:
        return None
    w = h = 0
    if src == path or seek:  # real size from the original, not the thumbnail
        m = re.search(rb"Video: .*?, (\d{2,5})x(\d{2,5})", p.stderr)
        if m:
            w, h = int(m.group(1)), int(m.group(2))
    else:
        try:
            q = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                "stream=width,height", "-of", "csv=p=0", path], capture_output=True, timeout=15)
            w, h = (int(x) for x in q.stdout.decode().strip().split(",")[:2])
        except Exception:
            pass
    return w, h, p.stdout[: N * N * 3]


def analyse(path):
    r = sample(path)
    if not r:
        return None
    w, h, raw = r
    buckets, lum, sat = {}, 0.0, 0.0
    px = [(raw[i], raw[i + 1], raw[i + 2]) for i in range(0, len(raw), 3)]
    for (R, G, B) in px:
        name = color_name(R, G, B)
        b = buckets.setdefault(name, [0, 0, 0, 0])
        b[0] += 1; b[1] += R; b[2] += G; b[3] += B
        lum += 0.2126 * R + 0.7152 * G + 0.0722 * B
        mx, mn = max(R, G, B), min(R, G, B)
        sat += (mx - mn) / 255
    n = len(px)
    top = sorted(buckets.items(), key=lambda kv: -kv[1][0])
    colors = {k: round(100 * v[0] / n) for k, v in top if 100 * v[0] / n >= 3}
    hexof = lambda v: "#%02x%02x%02x" % (v[1] // v[0], v[2] // v[0], v[3] // v[0])
    palette = [hexof(v) for _, v in top[:4]]
    # accent: the strongest actual color, even in a mostly-dark wallpaper
    chroma = [(k, v) for k, v in top if k not in ("black", "gray", "white") and v[0] / n >= 0.02]
    accent = chroma[0][0] if chroma else top[0][0]
    if chroma and hexof(chroma[0][1]) not in palette[:2]:
        palette = palette[:3] + [hexof(chroma[0][1])]
    return {"w": w, "h": h, "l": round(100 * lum / n / 255), "s": round(100 * sat / n),
            "c": colors, "a": accent, "p": palette}


def main():
    try:
        with open(OUT) as f:
            index = json.load(f)
    except Exception:
        index = {}
    files = []
    for dp, dn, fn in os.walk(ROOT, followlinks=True):
        dn[:] = [d for d in dn if not d.startswith(".")]
        for name in fn:
            if name.lower().endswith(IMG + VID):
                files.append(os.path.join(dp, name))
    present = set(files)
    for k in [k for k in index if k not in present]:
        del index[k]
    todo = []
    for f in files:
        try:
            m = int(os.path.getmtime(f))
        except OSError:
            continue
        e = index.get(f)
        if not e or e.get("m") != m or (not e.get("bad") and not e.get("t") and not f.lower().endswith(VID)):
            todo.append((f, m))

    # current wallpaper first, so "similar" works straight away
    try:
        with open(os.path.join(HOME, ".local/state/rice/colors.json")) as f:
            cur = json.load(f).get("wallpaper", "")
        todo.sort(key=lambda t: t[0] != cur)
    except Exception:
        pass

    def save():
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        tmp = OUT + ".tmp"
        with open(tmp, "w") as f:
            json.dump(index, f, separators=(",", ":"))
        os.replace(tmp, OUT)
        print("saved", flush=True)

    total = len(todo)
    print(f"progress 0 {total}", flush=True)
    if not total:
        return
    done, last = 0, time.time()

    def job(item):
        f, m = item
        e = analyse(f)
        return f, m, e

    with ThreadPoolExecutor(max_workers=max(2, (os.cpu_count() or 4) // 2)) as ex:
        for f, m, e in ex.map(job, todo):
            done += 1
            if e and not f.lower().endswith(VID):
                t = thumb_path(f)
                if os.path.exists(t) and os.path.getsize(t) > 0:
                    e["t"] = 1
            index[f] = dict(e, m=m) if e else {"m": m, "bad": 1}
            if done % 50 == 0:
                print(f"progress {done} {total}", flush=True)
            if time.time() - last > 8:
                save(); last = time.time()
    print(f"progress {done} {total}", flush=True)
    save()


if __name__ == "__main__":
    import fcntl
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    lock = open(OUT + ".lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("busy", flush=True)  # another indexer is running
        sys.exit(0)
    # stay out of the way: lowest CPU priority and idle-only disk access (inherited by ffmpeg)
    os.nice(19)
    try:
        subprocess.run(["ionice", "-c3", "-p", str(os.getpid())], capture_output=True)
    except Exception:
        pass
    main()
