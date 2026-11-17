#!/usr/bin/env python3
"""Static consistency checks for PaletteDesk Shell. No dependencies, no display needed.

The settings code relies on several lists being kept in sync by hand. This checks them:

  1. services/Settings.qml: `defaults` keys == JsonAdapter properties
  2. services/Presets.qml:  `lookKeys` is a subset of defaults, and `base` has exactly the lookKeys
  3. services/Settings.qml: hyprMap / hyprExtraKeys keys are real settings
  4. every `qs ipc call <target>` in scripts, Lua and QML has an IpcHandler with that target
  5. every bindActions `def` is bound in config/hypr/hyprland.lua (warning only when the bind is generated)

Usage: python3 tests/lint-settings.py        (exit status 1 on any error)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QS = os.path.join(ROOT, "config", "quickshell")
errors, warnings = [], []


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return f.read()


def block(text, start_pat, close_line):
    """Lines after the line matching start_pat, up to (not including) the first line equal to close_line."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if re.search(start_pat, line):
            out = []
            for l in lines[i + 1:]:
                if l.rstrip() == close_line:
                    return out
                out.append(l)
            break
    raise SystemExit(f"lint: could not find block starting at /{start_pat}/")


def top_level_keys(lines, lo, hi=None):
    """Quoted keys indented between lo and hi spaces (the source mixes 8 and 12 within one object)."""
    hi = lo if hi is None else hi
    pat = re.compile(r'^ {%d,%d}"([A-Za-z0-9_]+)"\s*:' % (lo, hi))
    return [m.group(1) for l in lines if (m := pat.match(l))]


settings = read("config", "quickshell", "services", "Settings.qml")
presets = read("config", "quickshell", "services", "Presets.qml")

# ---- 1. defaults vs JsonAdapter ---------------------------------------------------------
defaults = set(top_level_keys(block(settings, r"readonly property var defaults: \(\{", "    })"), 8, 12))
adapter_start = settings.index("JsonAdapter {")
adapter = set(re.findall(r"^\s+property\s+\w+\s+(\w+)\s*:", settings[adapter_start:], re.M))
for k in sorted(defaults - adapter):
    errors.append(f"Settings.qml: '{k}' is in defaults but has no JsonAdapter property")
for k in sorted(adapter - defaults):
    errors.append(f"Settings.qml: JsonAdapter property '{k}' is missing from defaults")

# ---- 2. lookKeys / base -----------------------------------------------------------------
look_text = re.search(r"readonly property var lookKeys: \[(.*?)\n    \]", presets, re.S).group(1)
look = set(re.findall(r'"([A-Za-z0-9_]+)"', look_text))
base_text = re.search(r"readonly property var base: \(\{(.*?)\n    \}\)", presets, re.S).group(1)
base = set(re.findall(r'"([A-Za-z0-9_]+)"\s*:', base_text))
base -= {"left", "center", "right"}   # nested barLayout keys
for k in sorted(look - defaults):
    errors.append(f"Presets.qml: lookKeys has '{k}', which is not a setting")
for k in sorted(look - base):
    errors.append(f"Presets.qml: lookKey '{k}' is missing from base")
for k in sorted(base - look):
    errors.append(f"Presets.qml: base has '{k}', which is not in lookKeys")

# ---- 3. hyprMap / hyprExtraKeys ---------------------------------------------------------
hypr_map = set(top_level_keys(block(settings, r"readonly property var hyprMap: \(\{", "    })"), 8, 12))
for k in sorted(hypr_map - defaults):
    errors.append(f"Settings.qml: hyprMap has '{k}', which is not a setting")
extra = set(re.findall(r'"([A-Za-z0-9_]+)"', re.search(r"hyprExtraKeys: \[(.*?)\]", settings, re.S).group(1)))
for k in sorted(extra - defaults):
    errors.append(f"Settings.qml: hyprExtraKeys has '{k}', which is not a setting")

# ---- 4. IPC targets ---------------------------------------------------------------------
handlers = set()
for dirpath, _, files in os.walk(QS):
    for f in files:
        if f.endswith(".qml"):
            txt = open(os.path.join(dirpath, f), encoding="utf-8").read()
            for m in re.finditer(r"IpcHandler\s*\{[^}]*?target:\s*\"([\w-]+)\"", txt, re.S):
                handlers.add(m.group(1))
callers = {}
scan_roots = [QS, os.path.join(ROOT, "config", "hypr"), os.path.join(ROOT, "scripts"), os.path.join(ROOT, "nixos")]
for root in scan_roots:
    for dirpath, _, files in os.walk(root):
        for f in files:
            if f.endswith((".qml", ".lua", ".sh", ".py", ".nix", ".md")):
                p = os.path.join(dirpath, f)
                for m in re.finditer(r"qs ipc call ([\w-]+)", open(p, encoding="utf-8").read()):
                    callers.setdefault(m.group(1), p)
for target, where in sorted(callers.items()):
    if target not in handlers:
        errors.append(f"'qs ipc call {target}' (in {os.path.relpath(where, ROOT)}) has no IpcHandler with that target")

# ---- 5. bindActions vs hyprland.lua -----------------------------------------------------
lua = read("config", "hypr", "hyprland.lua")
acts = re.findall(r'id:\s*"(\w+)".*?def:\s*"([^"]+)"', settings)
for ident, d in acts:
    parts = [p.strip() for p in d.split("+")]
    if parts[0] == "SUPER":
        needle = 'mainMod .. " + ' + " + ".join(parts[1:]) + '"'
    else:
        needle = '"' + " + ".join(parts) + '"'
    if needle not in lua and d not in lua:
        warnings.append(f"bindActions '{ident}' default '{d}' is not literally bound in hyprland.lua (fine if generated)")

# ---- report -----------------------------------------------------------------------------
print(f"settings: {len(defaults)} keys | lookKeys: {len(look)} | hyprMap: {len(hypr_map)} | "
      f"ipc targets: {len(handlers)} | binds: {len(acts)}")
for w in warnings:
    print("warning:", w)
for e in errors:
    print("ERROR:", e)
if errors:
    print(f"\n{len(errors)} error(s)")
    sys.exit(1)
print("ok")
