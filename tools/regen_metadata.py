#!/usr/bin/env python3
"""Regenerate metadata.json from the TASVideos API.

Replaces the 2013 YouTube-only metadata with archive.org direct .mp4 URLs,
which AVPlayer can stream without embed restrictions.
"""

import json
import sys
import time
import urllib.request

API = "https://tasvideos.org/api/v1/publications"
HEADERS = {"User-Agent": "Mozilla/5.0 SpeedS@ver-regen"}

PREFERRED_QUALITIES = ["_512kb.mp4", ".mp4", ".mkv"]


def fetch_page(page: int, size: int = 100):
    url = f"{API}?pageSize={size}&currentPage={page}"
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def pick_archive_url(urls):
    archives = [u for u in urls if "archive.org" in u]
    for q in PREFERRED_QUALITIES:
        for u in archives:
            if u.lower().endswith(q):
                return u
    return archives[0] if archives else None


def main():
    by_system: dict[str, list[dict]] = {}
    page = 1
    seen_ids: set[int] = set()

    while True:
        items = fetch_page(page)
        if not items:
            break
        new = [i for i in items if i["id"] not in seen_ids]
        if not new:
            break
        for it in new:
            seen_ids.add(it["id"])
            url = pick_archive_url(it.get("urls") or [])
            if not url:
                continue
            sys_code = it.get("systemCode") or "Other"
            by_system.setdefault(sys_code, []).append({
                "name": it["title"],
                "url": url,
            })
        print(f"page {page}: +{len(new)} (total {len(seen_ids)})", file=sys.stderr)
        page += 1
        time.sleep(0.2)

    out = [{"console": k, "movies": v} for k, v in sorted(by_system.items())]
    json.dump(out, sys.stdout, ensure_ascii=False)
    print(
        f"\nwrote {sum(len(c['movies']) for c in out)} movies across "
        f"{len(out)} systems",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
