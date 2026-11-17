#!/usr/bin/env python3
"""Pick a random wallpaper that suits a look (used by the random theme button).

Reads ~/.cache/rice/wallindex.json (see index-walls.py): {path: {w,h,l(0-100 luma),s(0-100 saturation),a(accent name)}}.
Prints one path. Only still images at least 1900px wide. If nothing matches, the
filters are loosened step by step, so it always prints something when any image exists.

  random-wall.py --lmin 10 --lmax 50 --smin 15 [--accents blue,purple] [--avoid /path/current]
"""
import argparse, json, os, random, sys

ap = argparse.ArgumentParser()
ap.add_argument("--lmin", type=float, default=8)
ap.add_argument("--lmax", type=float, default=55)
ap.add_argument("--smin", type=float, default=0)
ap.add_argument("--accents", default="")
ap.add_argument("--avoid", default="")
a = ap.parse_args()

try:
    with open(os.path.expanduser("~/.cache/rice/wallindex.json")) as f:
        idx = json.load(f)
except Exception:
    sys.exit(0)

IMG = (".jpg", ".jpeg", ".png", ".webp")
accents = {x for x in a.accents.split(",") if x}
items = [(p, v) for p, v in idx.items()
         if p.lower().endswith(IMG) and v.get("w", 0) >= 1900 and v.get("h", 0) >= 1000 and os.path.exists(p)
         and "/Animated/" not in p]

def pick(lmin, lmax, smin, use_accents):
    return [p for p, v in items
            if lmin <= v.get("l", 50) <= lmax and v.get("s", 0) >= smin
            and (not use_accents or not accents or v.get("a") in accents)]

# strict -> loose
for lmin, lmax, smin, acc in [
    (a.lmin, a.lmax, a.smin, True),
    (a.lmin, a.lmax, a.smin, False),
    (a.lmin - 6, a.lmax + 10, a.smin / 2, False),
    (0, 65, 0, False),
]:
    c = pick(lmin, lmax, smin, acc)
    c = [p for p in c if p != a.avoid] or c
    if len(c) >= 5:
        print(random.choice(c))
        sys.exit(0)
c = pick(0, 100, 0, False)
if c:
    print(random.choice(c))
