#!/usr/bin/env python3
"""Print the colour-generation options from settings.json, one per line: mode, contrast, seed hex ('' = use the wallpaper), source colour index."""
import json, os, re
try:
    d = json.load(open(os.path.expanduser("~/.config/rice/settings.json")))
except Exception:
    d = {}
mode = d.get("colorMode", "dark")
mode = mode if mode in ("dark", "light") else "dark"
try:
    contrast = max(-1.0, min(1.0, float(d.get("colorContrast", 0))))
except Exception:
    contrast = 0.0
seed = d.get("colorSeed", "")
seed = seed if isinstance(seed, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", seed) else ""
try:
    idx = max(0, min(4, int(d.get("colorSourceIndex", 0))))
except Exception:
    idx = 0
print(mode, f"{contrast:.2f}", seed, idx, sep="\n")
