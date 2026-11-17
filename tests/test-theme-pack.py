#!/usr/bin/env python3
"""Tests for scripts/theme-pack.py. Runs in a throwaway HOME; no display or running shell needed.

  python3 tests/test-theme-pack.py       exit status 1 on any failure
"""
import io
import json
import os
import subprocess
import sys
import tarfile
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "config", "quickshell", "scripts", "theme-pack.py")
HOME = tempfile.mkdtemp(prefix="pd-themetest-")
ENV = {**os.environ, "HOME": HOME, "XDG_CONFIG_HOME": os.path.join(HOME, ".config")}
PRESETS = os.path.join(HOME, ".config", "rice", "presets.json")
passed = failed = 0


def run(*args):
    r = subprocess.run([sys.executable, "-I", TOOL, *args], capture_output=True, text=True, env=ENV)
    return r.returncode, (r.stdout + r.stderr).strip()


def check(label, cond, detail=""):
    global passed, failed
    if cond:
        passed += 1; print(f"  PASS {label}")
    else:
        failed += 1; print(f"  FAIL {label} {detail}")


def users():
    try:
        return json.load(open(PRESETS))["user"]
    except (OSError, ValueError, KeyError):
        return []


def make_pack(path, theme=None, extra=None, raw=None):
    """Write a pack. `extra` = {arcname: bytes}; `raw` = list of (TarInfo, bytes|None) added as-is."""
    with tarfile.open(path, "w:gz") as tar:
        if theme is not None:
            d = json.dumps(theme).encode(); ti = tarfile.TarInfo("theme.json"); ti.size = len(d); tar.addfile(ti, io.BytesIO(d))
        for n, b in (extra or {}).items():
            ti = tarfile.TarInfo(n); ti.size = len(b); tar.addfile(ti, io.BytesIO(b))
        for ti, b in (raw or []):
            tar.addfile(ti, io.BytesIO(b) if b is not None else None)


GOOD = {"format": 1, "name": "Test Theme", "colors": ["#112233", "#445566", "#778899"],
        "values": {"gapsIn": 7, "blurEnabled": True, "chipShape": "pill", "barOpacity": 0.4,
                   "barLayout": {"left": ["workspaces"], "center": ["clock"], "right": ["stats", "status"]}},
        "wallpaper": {"file": None, "source": None, "license": None}}

d = tempfile.mkdtemp(prefix="pd-packs-")
print("round trip")
src = json.dumps({"name": "Mine", "colors": ["#aabbcc"], "values": {**GOOD["values"], "keybinds": "{}", "windowRules": "[]"}})
code, out = run("export", "--theme-json", src, "--out", f"{d}/mine.pdtheme")
check("export succeeds", code == 0, out)
code, out = run("inspect", f"{d}/mine.pdtheme")
info = json.loads(out) if code == 0 else {}
check("export drops anything that is not a look setting", code == 0 and info.get("settings") == 5, out)
code, out = run("import", f"{d}/mine.pdtheme")
check("import succeeds", code == 0, out)
u = users()
check("the theme is stored with only its look settings", len(u) == 1 and u[0]["name"] == "Mine" and "keybinds" not in u[0]["values"], str(u))
code, out = run("import", f"{d}/mine.pdtheme")
check("importing the same name again renames it", code == 0 and [x["name"] for x in users()][-1].startswith("Mine (imported"), str([x["name"] for x in users()]))

print("wallpapers need a rights statement")
wall = f"{d}/w.png"; open(wall, "wb").write(b"\x89PNG\r\n\x1a\n" + b"0" * 100)
code, out = run("export", "--theme-json", src, "--out", f"{d}/nw.pdtheme", "--wallpaper", wall)
check("bundling without --rights is refused", code != 0 and "rights" in out, out)
code, out = run("export", "--theme-json", src, "--out", f"{d}/w.pdtheme", "--wallpaper", wall, "--rights", "my own render, CC0")
check("bundling with --rights works", code == 0, out)
code, out = run("import", f"{d}/w.pdtheme")
imp = os.path.join(HOME, "Pictures", "Wallpapers", "Imported")
check("the bundled wallpaper lands in Pictures/Wallpapers/Imported", code == 0 and os.path.isdir(imp) and len(os.listdir(imp)) == 1, out)

print("malicious packs are rejected and change nothing")
before = json.dumps(users())
def rejected(label, **kw):
    p = f"{d}/{label.replace(' ', '_')}.pdtheme"
    make_pack(p, **kw)
    code, out = run("import", p)
    check(label, code != 0 and json.dumps(users()) == before, f"code={code} {out}")
def with_values(**v):
    t = json.loads(json.dumps(GOOD)); t["values"].update(v); return t
rejected("keybinds in a pack", theme=with_values(keybinds='{"x":1}'))
rejected("window rules in a pack", theme=with_values(windowRules="[]"))
rejected("autostart in a pack", theme=with_values(autostart='["rm -rf ~"]'))
rejected("a shell command inside a text value", theme=with_values(chipShape="$(touch /tmp/pwned)"))
rejected("quotes inside a text value", theme=with_values(chipShape='pill"; os.execute("x")'))
rejected("a huge number", theme=with_values(gapsIn=10**9))
rejected("an unknown bar module", theme=with_values(barLayout={"left": ["evil"], "center": [], "right": []}))
rejected("a wrong format number", theme={**GOOD, "format": 2})
rejected("a bad swatch color", theme={**GOOD, "colors": ["red"]})
rejected("no theme.json", theme=None, extra={"preview.jpg": b"x"})
rejected("an unexpected file", theme=GOOD, extra={"run.sh": b"#!/bin/sh\nrm -rf ~\n"})
rejected("path traversal", theme=GOOD, extra={"../../.bashrc": b"evil"})
ti = tarfile.TarInfo("wallpaper.png"); ti.type = tarfile.SYMTYPE; ti.linkname = "/etc/passwd"
rejected("a symlink member", theme=GOOD, raw=[(ti, None)])
rejected("a pack naming a wallpaper it does not contain", theme={**GOOD, "wallpaper": {"file": "wallpaper.png", "source": None, "license": "x"}})
open(f"{d}/junk.pdtheme", "wb").write(b"not a tarball")
code, out = run("import", f"{d}/junk.pdtheme")
check("a file that is not a pack", code != 0 and json.dumps(users()) == before, out)
check("nothing was created outside Imported/", not os.path.exists("/tmp/pwned") and not os.path.exists(os.path.join(HOME, ".bashrc")))

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
