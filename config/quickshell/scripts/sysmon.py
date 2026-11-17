#!/usr/bin/env python3
"""System metrics for the system monitor popup: one JSON object per line, once a second.

  sysmon.py            run until killed
  sysmon.py --once     print a single sample (CPU numbers are 0 for the first sample)

Keys: cpu (total %), cores [%], mem {used,total,swap_used,swap_total} (MB), temps [{label,c}],
gpu {busy,vram_used,vram_total} (AMD sysfs, when present), disks [{mount,used,total}] (GB),
net {rx,tx} (bytes/s), procs [{name,cpu,mem}] (cpu = % of one core, mem = MB). Standard library only."""
import glob
import json
import os
import sys
import time

NCPU = os.cpu_count() or 1
PAGE = os.sysconf("SC_PAGE_SIZE")


def cpu_times():
    out = {}
    with open("/proc/stat") as f:
        for line in f:
            if line.startswith("cpu"):
                p = line.split()
                v = list(map(int, p[1:9]))
                out[p[0]] = (sum(v), v[3] + v[4])   # total, idle+iowait
    return out


def meminfo():
    m = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, _, v = line.partition(":")
            m[k] = int(v.split()[0]) // 1024
    return {"used": m["MemTotal"] - m["MemAvailable"], "total": m["MemTotal"],
            "swap_used": m["SwapTotal"] - m["SwapFree"], "swap_total": m["SwapTotal"]}


def temps():
    out = []
    for hw in sorted(glob.glob("/sys/class/hwmon/hwmon*")):
        try:
            name = open(hw + "/name").read().strip()
        except OSError:
            continue
        for t in sorted(glob.glob(hw + "/temp*_input")):
            try:
                c = int(open(t).read()) / 1000
                label = ""
                try:
                    label = open(t.replace("_input", "_label")).read().strip()
                except OSError:
                    pass
                out.append({"label": f"{name} {label}".strip(), "c": round(c, 1)})
            except (OSError, ValueError):
                pass
    return out[:8]


def gpu():
    for d in glob.glob("/sys/class/drm/card*/device"):
        try:
            busy = int(open(d + "/gpu_busy_percent").read())
            used = int(open(d + "/mem_info_vram_used").read()) // 1048576
            total = int(open(d + "/mem_info_vram_total").read()) // 1048576
            return {"busy": busy, "vram_used": used, "vram_total": total}
        except (OSError, ValueError):
            continue
    return None


def disks():
    out, seen = [], set()
    for mount in ("/", "/home", "/boot"):
        try:
            st = os.stat(mount)
            if st.st_dev in seen:
                continue
            seen.add(st.st_dev)
            v = os.statvfs(mount)
            total = v.f_blocks * v.f_frsize
            out.append({"mount": mount, "used": round((total - v.f_bavail * v.f_frsize) / 1e9, 1), "total": round(total / 1e9, 1)})
        except OSError:
            pass
    return out


def net_bytes():
    rx = tx = 0
    with open("/proc/net/dev") as f:
        for line in list(f)[2:]:
            name, _, rest = line.partition(":")
            if name.strip() == "lo":
                continue
            p = rest.split()
            rx += int(p[0])
            tx += int(p[8])
    return rx, tx


def proc_ticks():
    out = {}
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        try:
            with open(f"/proc/{d}/stat") as f:
                s = f.read()
            after = s[s.rindex(")") + 2:].split()
            ticks = int(after[11]) + int(after[12])
            with open(f"/proc/{d}/comm") as f:
                name = f.read().strip()
            with open(f"/proc/{d}/statm") as f:
                rss = int(f.read().split()[1]) * PAGE // 1048576
            out[int(d)] = (ticks, name, rss)
        except (OSError, ValueError, IndexError):
            pass
    return out


def main():
    once = "--once" in sys.argv
    prev_cpu, prev_proc, prev_net, prev_t = cpu_times(), proc_ticks(), net_bytes(), time.time()
    first = True
    while True:
        time.sleep(0.2 if once else 1.0)
        now_cpu, now_proc, now_net, now_t = cpu_times(), proc_ticks(), net_bytes(), time.time()
        dt = max(0.001, now_t - prev_t)

        def pct(key):
            t0, i0 = prev_cpu.get(key, (0, 0)); t1, i1 = now_cpu.get(key, (0, 0))
            return round(100 * (1 - (i1 - i0) / (t1 - t0)), 1) if t1 > t0 else 0.0
        total_delta = max(1, now_cpu["cpu"][0] - prev_cpu["cpu"][0])
        procs = []
        for pid, (ticks, name, rss) in now_proc.items():
            old = prev_proc.get(pid)
            cpu = round((ticks - old[0]) / total_delta * 100 * NCPU, 1) if old else 0.0
            procs.append({"name": name, "cpu": cpu, "mem": rss})
        procs.sort(key=lambda p: (-p["cpu"], -p["mem"]))
        sample = {
            "cpu": pct("cpu"), "cores": [pct(f"cpu{i}") for i in range(NCPU)], "mem": meminfo(), "temps": temps(),
            "gpu": gpu(), "disks": disks(),
            "net": {"rx": int((now_net[0] - prev_net[0]) / dt), "tx": int((now_net[1] - prev_net[1]) / dt)},
            "procs": procs[:6],
        }
        print(json.dumps(sample), flush=True)
        if once:
            return
        prev_cpu, prev_proc, prev_net, prev_t = now_cpu, now_proc, now_net, now_t
        first = False


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
