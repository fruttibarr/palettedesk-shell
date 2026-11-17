#!/usr/bin/env python3
"""Fetch lyrics for one track from LRCLIB (https://lrclib.net), with a disk cache.

usage: lyrics.py KEY TITLE ARTIST ALBUM DURATION_SECONDS
prints one JSON object: {key, status, synced, plain, source}
  status: "synced" | "plain" | "instrumental" | "notfound" | "error"
KEY is echoed back so the caller can drop answers for a track that already changed.
"""
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://lrclib.net/api"
UA = "rice-lyrics/1.0 (quickshell bar widget)"
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "rice", "lyrics")


def http(path, params):
    url = f"{API}/{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=12) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def clean_title(t):
    """Drop the decorations players add: (feat. X), - Remastered 2011, [Live] ..."""
    t = re.sub(r"\s*[\(\[][^\)\]]*(feat\.?|ft\.?|with|remaster|version|edit|live|mono|stereo|bonus|deluxe|explicit)[^\)\]]*[\)\]]", "", t, flags=re.I)
    t = re.sub(r"\s+-\s+.*(remaster|version|edit|live|mono|stereo|bonus|single|mix).*$", "", t, flags=re.I)
    return t.strip() or t


def first_artist(a):
    return re.split(r"\s*(?:,|;|&| feat\.? | ft\.? | x )\s*", a, maxsplit=1, flags=re.I)[0].strip() or a


def norm(s):
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def pick(results, title, artist, duration):
    """Best search hit: right song first, then synced over plain, then closest length."""
    best, best_score = None, None
    for r in results or []:
        if not (r.get("syncedLyrics") or r.get("plainLyrics") or r.get("instrumental")):
            continue
        rt, ra = norm(r.get("trackName") or ""), norm(r.get("artistName") or "")
        t, a = norm(title), norm(artist)
        if not (t and (t in rt or rt in t)):
            continue
        if a and ra and not (a in ra or ra in a):
            continue
        diff = abs((r.get("duration") or 0) - duration) if duration else 0
        if duration and diff > 12:
            continue          # a different cut: its timestamps would be off
        score = (0 if r.get("syncedLyrics") else 1, diff)
        if best_score is None or score < best_score:
            best, best_score = r, score
    return best


def lookup(title, artist, album, duration):
    ct, fa = clean_title(title), first_artist(artist)
    tries = []
    base = {"track_name": title, "artist_name": artist}
    if duration:
        base["duration"] = round(duration)
    if album and album != "?":
        tries.append({**base, "album_name": album})
    tries.append(base)
    if (ct, fa) != (title, artist):
        tries.append({**base, "track_name": ct, "artist_name": fa})

    hit = None
    for params in tries:
        r = http("get", params)
        if r and (r.get("syncedLyrics") or r.get("instrumental")):
            return r
        hit = hit or r      # plain-only: keep it, but a search may find a synced one

    for params in ({"track_name": ct, "artist_name": fa}, {"q": f"{ct} {fa}"}):
        r = pick(http("search", params), ct, fa, duration)
        if r and (r.get("syncedLyrics") or r.get("instrumental")):
            return r
        hit = hit or r
    return hit


def main():
    key, title, artist, album, dur = (sys.argv[1:6] + [""] * 5)[:5]
    try:
        duration = float(dur)
    except ValueError:
        duration = 0.0

    out = {"key": key, "status": "notfound", "synced": "", "plain": "", "source": "lrclib"}
    ident = "\x1f".join([norm(title), norm(artist), str(round(duration))])
    cache_file = os.path.join(CACHE, hashlib.sha1(ident.encode()).hexdigest() + ".json")

    try:
        with open(cache_file) as f:
            cached = json.load(f)
        cached["key"] = key
        cached["source"] = "cache"
        print(json.dumps(cached))
        return
    except (OSError, ValueError):
        pass

    try:
        r = lookup(title, artist, album, duration)
    except Exception as e:  # offline, timeout, bad JSON: don't cache, try again next time
        out["status"] = "error"
        out["error"] = str(e)
        print(json.dumps(out))
        return

    if r:
        out["synced"] = r.get("syncedLyrics") or ""
        out["plain"] = r.get("plainLyrics") or ""
        out["status"] = ("synced" if out["synced"] else "instrumental" if r.get("instrumental")
                         else "plain" if out["plain"] else "notfound")

    # misses are not cached: lyrics get added to LRCLIB over time
    try:
        os.makedirs(CACHE, exist_ok=True)
        if out["status"] != "notfound":
            with open(cache_file, "w") as f:
                json.dump(out, f)
    except OSError:
        pass
    print(json.dumps(out))


if __name__ == "__main__":
    main()
