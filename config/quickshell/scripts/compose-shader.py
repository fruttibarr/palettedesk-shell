#!/usr/bin/env python3
"""Build a full-screen shader that applies colour adjustments, optionally on top of one of the shipped effects.

  compose-shader.py OUT.frag EFFECT|- brightness contrast saturation vibrance gamma hue red green blue blacklight

The output name is chosen by the shell (it contains a hash of the settings, so Hyprland always loads fresh content).
Values are clamped here; nothing user-provided is pasted into the shader as text. Standard library only."""
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SHADERS = os.path.join(os.path.expanduser("~"), ".config", "hypr", "shaders")
LIMITS = [(-0.5, 0.5), (0.3, 2.0), (0.0, 3.0), (0.0, 1.0), (0.3, 3.0), (-180, 180), (0.3, 2.0), (0.3, 2.0), (0.3, 2.0), (0.0, 1.0)]

HEAD = """#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;
"""
BASE = "void presetMain() { fragColor = texture(tex, v_texcoord); }\n"


def main():
    if len(sys.argv) != 13:
        sys.exit("usage: compose-shader.py OUT EFFECT|- 10 numbers")
    out, effect = sys.argv[1], sys.argv[2]
    vals = []
    for raw, (lo, hi) in zip(sys.argv[3:], LIMITS):
        v = float(raw)
        if not math.isfinite(v):
            sys.exit("bad number")
        vals.append(min(hi, max(lo, v)))
    br, ct, sat, vib, gam, hue, r, g, b, bl = vals
    body = BASE
    if effect != "-":
        if not re.fullmatch(r"[A-Za-z0-9_-]+", effect):
            sys.exit("bad effect name")
        for d in (SHADERS, os.path.join(HERE, "..", "..", "hypr", "shaders")):
            p = os.path.join(d, effect + ".frag")
            if os.path.isfile(p):
                src = open(p, encoding="utf-8").read()
                break
        else:
            sys.exit("no such effect")
        # keep the effect's own declarations; drop its header, rename its main()
        src = re.sub(r"^#version[^\n]*\n", "", src)
        src = re.sub(r"^precision[^\n]*\n", "", src, flags=re.M)
        src = re.sub(r"^in vec2 v_texcoord;\n", "", src, flags=re.M)
        src = re.sub(r"^uniform sampler2D tex;\n", "", src, flags=re.M)
        src = re.sub(r"^layout\(location\s*=\s*0\)\s*out vec4 fragColor;\n", "", src, flags=re.M)
        body, n = re.subn(r"void\s+main\s*\(\s*\)", "void presetMain()", src, count=1)
        if not n:
            sys.exit("effect has no main()")
    c, s = math.cos(math.radians(hue)), math.sin(math.radians(hue))
    k = s / math.sqrt(3.0)
    adjust = f"""
void main() {{
    presetMain();
    vec3 c = fragColor.rgb;
    c += {br:.5f};
    c = (c - 0.5) * {ct:.5f} + 0.5;
    c = pow(max(c, vec3(0.0)), vec3(1.0 / {gam:.5f}));
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
    float boost = {sat:.5f} + {vib:.5f} * (1.0 - (mx - mn));      // vibrance lifts dull colours more than vivid ones
    c = mix(vec3(l), c, boost);
    float S = c.r + c.g + c.b;
    c = vec3({c:.5f} * c.r + {(1 - c) / 3:.5f} * S + {k:.5f} * (c.b - c.g),
             {c:.5f} * c.g + {(1 - c) / 3:.5f} * S + {k:.5f} * (c.r - c.b),
             {c:.5f} * c.b + {(1 - c) / 3:.5f} * S + {k:.5f} * (c.g - c.r));
    c *= vec3({r:.5f}, {g:.5f}, {b:.5f});
    // blacklight: deep violet-black room, bright colours glow like fluorescent paint under UV
    float peak = max(c.r, max(c.g, c.b));
    float glow = smoothstep(0.25, 0.85, peak);
    vec3 uv = vec3(0.55, 0.12, 1.15);
    c = mix(c, c * uv * 1.5, {bl:.5f} * 0.75);
    c = mix(c, c * 1.0 + vec3(0.10, 0.02, 0.22) * glow, {bl:.5f});
    c *= 1.0 - 0.38 * {bl:.5f};
    fragColor = vec4(clamp(c, 0.0, 1.0), fragColor.a);
}}
"""
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    if os.path.exists(out):
        return
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(HEAD + body + adjust)
    os.replace(tmp, out)
    # keep the folder small: drop older generated files
    d = os.path.dirname(os.path.abspath(out))
    old = sorted((os.path.join(d, n) for n in os.listdir(d) if n.startswith("c-") and n.endswith(".frag")), key=os.path.getmtime)
    for p in old[:-6]:
        os.remove(p)


main()
