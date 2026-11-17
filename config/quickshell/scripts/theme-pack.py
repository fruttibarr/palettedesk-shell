#!/usr/bin/env python3
"""Theme packs (.pdtheme): share a look without sharing anything that can run code.

  theme-pack.py export --theme-json JSON --out FILE [--wallpaper FILE --rights TEXT] [--source TEXT] [--notify]
  theme-pack.py import FILE [--notify]
  theme-pack.py inspect FILE

A pack is a .tar.gz holding theme.json (+ preview.jpg, + wallpaper.<ext> only if the exporter confirmed they have the
right to share it). Import accepts ONLY the visual settings listed as `lookKeys` in services/Presets.qml, each checked
for type and size. Keybinds, commands, paths and window rules can never be carried: they are rejected, not ignored.
Standard library only (ffmpeg, if present, makes the preview)."""
import argparse
import hashlib
import io
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

HOME = os.path.expanduser("~")
STATE = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
PRESETS = os.path.join(STATE, "rice", "presets.json")
IMPORT_DIR = os.path.join(HOME, "Pictures", "Wallpapers", "Imported")
HERE = os.path.dirname(os.path.abspath(__file__))
MODULES = {"workspaces", "media", "lyrics", "record", "clock", "title", "tray", "stats", "status", "launcher", "power", "kbd"}
WALL_EXT = {"jpg", "jpeg", "png", "webp", "gif", "mp4", "webm"}
MAX_JSON, MAX_WALL = 64 * 1024, 80 * 1024 * 1024
SAFE_STR = re.compile(r"^[A-Za-z0-9 _.%#:,+()-]{0,64}$")
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


class PackError(Exception):
    pass


def notify(msg, body="", critical=False):
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "-a", "Theme pack", *(["-u", "critical"] if critical else []), msg, body], check=False)


def look_keys():
    """The settings a theme may own, read from the shell's own list so the two can never drift apart."""
    for path in (os.path.join(HERE, "..", "services", "Presets.qml"), os.path.join(STATE, "quickshell", "services", "Presets.qml")):
        try:
            text = open(path, encoding="utf-8").read()
            block = re.search(r"readonly property var lookKeys: \[(.*?)\]", text, re.S).group(1)
            return set(re.findall(r'"([A-Za-z0-9_]+)"', block))
        except (OSError, AttributeError):
            continue
    raise PackError("cannot find the shell's lookKeys (is the shell installed?)")


def builtin_names():
    for path in (os.path.join(HERE, "..", "services", "Presets.qml"), os.path.join(STATE, "quickshell", "services", "Presets.qml")):
        try:
            return {n.lower() for n in re.findall(r'^\s+name: "([^"]+)"', open(path, encoding="utf-8").read(), re.M)}
        except OSError:
            continue
    return set()


def check_value(key, v):
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        if not math.isfinite(v) or abs(v) > 10000:
            raise PackError(f"{key}: number out of range")
        return v
    if isinstance(v, str):
        if not SAFE_STR.match(v):
            raise PackError(f"{key}: text has characters a theme may not use")
        return v
    if key == "barLayout" and isinstance(v, dict):
        out = {}
        for zone, mods in v.items():
            if zone not in ("left", "center", "right") or not isinstance(mods, list):
                raise PackError("barLayout: bad structure")
            if any(m not in MODULES for m in mods):
                raise PackError("barLayout: unknown bar module")
            out[zone] = list(mods)
        return out
    raise PackError(f"{key}: unsupported value type")


def validate_theme(t, allowed):
    if not isinstance(t, dict) or t.get("format") != 1:
        raise PackError("not a PaletteDesk theme pack (format 1)")
    name = str(t.get("name", "")).strip()
    if not name or len(name) > 40 or not SAFE_STR.match(name):
        raise PackError("bad theme name")
    values = t.get("values")
    if not isinstance(values, dict):
        raise PackError("no values")
    bad = sorted(set(values) - allowed)
    if bad:
        raise PackError("this pack tries to set things a theme may not touch: " + ", ".join(bad[:6]))
    clean = {k: check_value(k, v) for k, v in values.items()}
    colors = t.get("colors") or []
    if not (isinstance(colors, list) and len(colors) <= 3 and all(isinstance(c, str) and HEX.match(c) for c in colors)):
        raise PackError("bad swatch colors")
    return name, clean, colors


# --------------------------------------------------------------------------- export
def cmd_export(a):
    allowed = look_keys()
    src = json.loads(a.theme_json)
    values = {k: v for k, v in (src.get("values") or {}).items() if k in allowed}
    theme = {"format": 1, "name": str(src.get("name", "Theme"))[:40], "colors": [c for c in (src.get("colors") or []) if isinstance(c, str) and HEX.match(c)][:3],
             "values": values, "wallpaper": {"file": None, "source": a.source or None, "license": None}}
    validate_theme(theme, allowed)       # never write a pack we would refuse to read
    files = {}
    if a.wallpaper:
        if not (a.rights or "").strip():
            raise PackError("bundling a wallpaper needs --rights: state that you have the right to share it")
        ext = os.path.splitext(a.wallpaper)[1].lstrip(".").lower()
        if ext not in WALL_EXT:
            raise PackError("unsupported wallpaper type")
        if os.path.getsize(a.wallpaper) > MAX_WALL:
            raise PackError("wallpaper is larger than 80 MB")
        theme["wallpaper"] = {"file": f"wallpaper.{ext}", "source": a.source or None, "license": a.rights.strip()[:200]}
        files[f"wallpaper.{ext}"] = a.wallpaper
        if ext in ("jpg", "jpeg", "png", "webp") and shutil.which("ffmpeg"):
            prev = tempfile.mktemp(suffix=".jpg")
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", a.wallpaper, "-vf", "scale=480:-2", "-q:v", "5", prev], check=False)
            if os.path.exists(prev):
                files["preview.jpg"] = prev
    data = json.dumps(theme, indent=2).encode()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with tarfile.open(a.out, "w:gz") as tar:
        info = tarfile.TarInfo("theme.json"); info.size = len(data); info.mode = 0o644
        tar.addfile(info, io.BytesIO(data))
        for arc, path in files.items():
            tar.add(path, arcname=arc, filter=lambda ti: (setattr(ti, "uid", 0) or setattr(ti, "gid", 0) or setattr(ti, "uname", "") or setattr(ti, "gname", "") or setattr(ti, "mode", 0o644) or ti))
    msg = f"Exported \"{theme['name']}\" to {a.out}" + (" with its wallpaper" if a.wallpaper else " (settings only)")
    print(msg)
    if a.notify:
        notify("Theme exported", msg)


# --------------------------------------------------------------------------- import
def read_pack(path, allowed):
    """Return (name, values, colors, theme, {arcname: bytes}) or raise PackError. Nothing touches disk here."""
    try:
        tar = tarfile.open(path, "r:gz")
    except (tarfile.TarError, OSError) as e:
        raise PackError(f"cannot open the pack: {e}")
    data = {}
    with tar:
        for m in tar.getmembers():
            n = m.name
            if not m.isfile() or "/" in n or n.startswith("."):
                raise PackError(f"unexpected entry in the pack: {n}")
            ok = n in ("theme.json", "preview.jpg") or re.fullmatch(r"wallpaper\.(%s)" % "|".join(WALL_EXT), n)
            if not ok:
                raise PackError(f"unexpected file in the pack: {n}")
            limit = MAX_JSON if n == "theme.json" else MAX_WALL
            if m.size > limit:
                raise PackError(f"{n} is too large")
            data[n] = tar.extractfile(m).read()
    if "theme.json" not in data:
        raise PackError("theme.json is missing")
    try:
        theme = json.loads(data["theme.json"])
    except ValueError:
        raise PackError("theme.json is not valid JSON")
    name, values, colors = validate_theme(theme, allowed)
    return name, values, colors, theme, data


def cmd_inspect(a):
    name, values, colors, theme, data = read_pack(a.file, look_keys())
    print(json.dumps({"name": name, "colors": colors, "settings": len(values), "wallpaper": theme["wallpaper"], "files": sorted(data)}, indent=2))


def cmd_import(a):
    name, values, colors, theme, data = read_pack(a.file, look_keys())
    wall = still = ""
    wf = (theme.get("wallpaper") or {}).get("file")
    if wf:
        if wf not in data:
            raise PackError("the pack names a wallpaper it does not contain")
        os.makedirs(IMPORT_DIR, exist_ok=True)
        ext = wf.rsplit(".", 1)[1]
        dest = os.path.join(IMPORT_DIR, re.sub(r"[^A-Za-z0-9_-]+", "-", name).strip("-")[:30] + "-" + hashlib.sha256(data[wf]).hexdigest()[:8] + "." + ext)
        with open(dest, "wb") as f:
            f.write(data[wf])
        wall = dest
        still = dest if ext in ("jpg", "jpeg", "png", "webp") else ""
    try:
        store = json.load(open(PRESETS, encoding="utf-8"))
    except (OSError, ValueError):
        store = {}
    user = store.get("user", [])
    taken = {u.get("name", "").lower() for u in user} | builtin_names()
    final, n = name, 1
    while final.lower() in taken:
        n += 1; final = f"{name} (imported{'' if n == 2 else ' ' + str(n - 1)})"[:48]
    user.append({"name": final, "wallpaper": wall, "still": still, "colors": colors, "values": values})
    store["user"] = user
    os.makedirs(os.path.dirname(PRESETS), exist_ok=True)
    tmp = PRESETS + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(store, f, indent=4)
    os.replace(tmp, PRESETS)
    msg = f"Imported \"{final}\" ({len(values)} settings" + (", with its wallpaper)" if wall else ")")
    print(msg)
    if a.notify:
        notify("Theme imported", msg + ". Find it on the Themes page.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("export"); p.add_argument("--theme-json", required=True); p.add_argument("--out", required=True)
    p.add_argument("--wallpaper"); p.add_argument("--rights"); p.add_argument("--source"); p.add_argument("--notify", action="store_true")
    p = sub.add_parser("import"); p.add_argument("file"); p.add_argument("--notify", action="store_true")
    p = sub.add_parser("inspect"); p.add_argument("file")
    a = ap.parse_args()
    try:
        {"export": cmd_export, "import": cmd_import, "inspect": cmd_inspect}[a.cmd](a)
    except PackError as e:
        print(f"error: {e}", file=sys.stderr)
        if getattr(a, "notify", False):
            notify("Theme pack problem", str(e), critical=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
