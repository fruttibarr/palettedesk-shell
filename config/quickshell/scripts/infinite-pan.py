#!/usr/bin/env python3
"""Infinite desktop. Usage: infinite-pan.py start|stop|home|zoomout|zoomin|retile
start:   pans every floating window of the active workspace by the cursor
         movement until `stop` (button release) is called.
zoomout/zoomin: scale all floating windows of the workspace about the cursor.
home:    undo the accumulated pan and zoom of the active workspace."""
import json, os, signal, socket, sys, time

ZMIN, STEP = 0.25, 0.9
RT = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") or os.listdir(f"{RT}/hypr")[0]
SOCK = f"{RT}/hypr/{SIG}/.socket.sock"
PID = f"{RT}/rice-infinite-pan.pid"
STATE = os.path.expanduser("~/.cache/rice/infinite-offsets.json")


def hypr(cmd):
    s = socket.socket(socket.AF_UNIX)
    s.connect(SOCK)
    s.sendall(cmd.encode())
    out = b""
    while True:
        b = s.recv(65536)
        if not b:
            break
        out += b
    s.close()
    return out.decode()


def jget(what):
    return json.loads(hypr("j/" + what))


def load():
    try:
        return json.load(open(STATE))
    except Exception:
        return {}


def save(d):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    json.dump(d, open(STATE, "w"))


def get(st, ws):  # [tx, ty, zoom]
    v = st.get(str(ws), [0, 0, 1.0])
    return v if len(v) >= 3 else [v[0], v[1], 1.0]


def floater_info(ws):
    return [c for c in jget("clients")
            if c["workspace"]["id"] == ws and c["mapped"] and not c["fullscreen"]
            and not c["pinned"] and c["floating"]]


def move_cmds(addrs, dx, dy):
    return "[[BATCH]]" + ";".join(
        f'dispatch hl.dsp.window.move({{ x = {dx}, y = {dy}, relative = true, window = "address:{a}" }})'
        for a in addrs)


def place(c, x, y, w, h):
    a = c["address"]
    hypr("[[BATCH]]"
         f'dispatch hl.dsp.window.resize({{ x = {round(w)}, y = {round(h)}, window = "address:{a}" }});'
         f'dispatch hl.dsp.window.move({{ x = {round(x)}, y = {round(y)}, window = "address:{a}" }})')


def tile_to_float(ws):
    # Make tiled windows free-floating so they take part in the infinite canvas.
    for c in jget("clients"):
        if c["workspace"]["id"] == ws and c["mapped"] and not c["floating"] and not c["fullscreen"]:
            hypr(f'dispatch hl.dsp.window.float({{ action = "enable", window = "address:{c["address"]}" }})')


def stop():
    try:
        os.kill(int(open(PID).read()), signal.SIGTERM)
    except Exception:
        pass


def start():
    stop()
    open(PID, "w").write(str(os.getpid()))
    ws = jget("activeworkspace")["id"]
    aw = jget("activewindow")
    if aw and aw.get("fullscreen"):
        return
    tile_to_float(ws)
    addrs = [c["address"] for c in floater_info(ws)]
    c = jget("cursorpos")
    lx, ly = c["x"], c["y"]
    total = [0, 0]
    running = [True]
    signal.signal(signal.SIGTERM, lambda *_: running.__setitem__(0, False))
    t0 = last_refresh = time.time()
    while running[0] and time.time() - t0 < 600:
        c = jget("cursorpos")
        dx, dy = c["x"] - lx, c["y"] - ly
        if dx or dy:
            hypr(move_cmds(addrs, dx, dy))
            lx, ly = c["x"], c["y"]
            total[0] += dx
            total[1] += dy
        if time.time() - last_refresh > 1:
            addrs = [c["address"] for c in floater_info(ws)]
            last_refresh = time.time()
        time.sleep(0.008)
    st = load()
    tx, ty, z = get(st, ws)
    st[str(ws)] = [tx + total[0], ty + total[1], z]
    save(st)
    try:
        os.remove(PID)
    except Exception:
        pass


def zoom(f):
    ws = jget("activeworkspace")["id"]
    st = load()
    tx, ty, z = get(st, ws)
    nz = max(ZMIN, min(1.0, z * f))
    f = nz / z
    if abs(f - 1) < 1e-6:
        return
    tile_to_float(ws)
    c = jget("cursorpos")
    cx, cy = c["x"], c["y"]
    for w in floater_info(ws):
        place(w, cx + (w["at"][0] - cx) * f, cy + (w["at"][1] - cy) * f,
              w["size"][0] * f, w["size"][1] * f)
    st[str(ws)] = [cx + (tx - cx) * f, cy + (ty - cy) * f, nz]
    save(st)


def home():
    ws = jget("activeworkspace")["id"]
    st = load()
    tx, ty, z = get(st, ws)
    st.pop(str(ws), None)
    for w in floater_info(ws):
        place(w, (w["at"][0] - tx) / z, (w["at"][1] - ty) / z, w["size"][0] / z, w["size"][1] / z)
    save(st)


def retile():
    # Infinite desktop turned off: drop the pan/zoom and tile every floating window again.
    stop()
    try:
        os.remove(STATE)
    except Exception:
        pass
    for c in jget("clients"):
        if c["mapped"] and c["floating"] and not c["pinned"] and not c["fullscreen"] \
                and not c["workspace"]["name"].startswith("special"):
            hypr(f'dispatch hl.dsp.window.float({{ action = "disable", window = "address:{c["address"]}" }})')


if __name__ == "__main__":
    {"start": start, "stop": stop, "home": home, "retile": retile,
     "zoomout": lambda: zoom(STEP), "zoomin": lambda: zoom(1 / STEP)}[sys.argv[1] if len(sys.argv) > 1 else "start"]()
