#!/usr/bin/env python3
"""Fetch the full Claude Code blog index (title, url, date) as JSON.

The category page at https://claude.com/blog-category/claude-code renders its
"View more" pagination server-side (Webflow: a `?<listid>_page=N` query param
found on the `w-pagination-next` anchor), so plain HTTP is enough — no
browser needed. Cards carry `fs-list-field="date"` and `data-cta-copy`
attributes, which this script pairs into records.

Usage:
    fetch_index.py [--floor YYYY-MM-DD] [--max-pages N]

Stops paging when every post on a page is older than --floor (default
2025-11-01), when a page adds no new URLs, or after --max-pages (default 20,
a runaway guard). Output: JSON array of {url, title, date} sorted newest
first, floor-filtered.
"""

import argparse
import html as html_mod
import json
import re
import sys
import urllib.request
from datetime import date, datetime

BASE = "https://claude.com"
CATEGORY = f"{BASE}/blog-category/claude-code"
UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}

# A card's date div precedes its link block; non-greedy pairing keeps each
# date matched to the nearest following blog link.
CARD_RE = re.compile(
    r'fs-list-field="date">([^<]+)</div>'
    r'.*?data-cta-copy="([^"]*)"[^>]*href="(/blog/[a-z0-9-]+)"',
    re.S,
)
# Match the next-page anchor tag first, then pull its href, so Webflow
# reordering the tag's attributes can't silently end pagination early.
NEXT_A_RE = re.compile(r'<a\b[^>]*class="[^"]*w-pagination-next[^"]*"[^>]*>')
HREF_RE = re.compile(r'href="(\?[0-9a-f]+_page=\d+)"')


def fetch(url: str) -> str:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def parse_date(text: str) -> date | None:
    try:
        return datetime.strptime(text.strip(), "%B %d, %Y").date()
    except ValueError:
        print(f"warning: unparseable date {text.strip()!r}; post skipped",
              file=sys.stderr)
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--floor", default="2025-11-01",
                    help="ignore posts published before this date (YYYY-MM-DD)")
    ap.add_argument("--max-pages", type=int, default=20)
    args = ap.parse_args()
    floor = date.fromisoformat(args.floor)

    posts: dict[str, dict] = {}
    url = CATEGORY
    for _ in range(args.max_pages):
        html = fetch(url)
        page_dates = []
        added = 0
        for raw_date, title, path in CARD_RE.findall(html):
            d = parse_date(raw_date)
            if d is None:
                continue
            page_dates.append(d)
            full = BASE + path
            if d >= floor and full not in posts:
                posts[full] = {"url": full,
                               "title": html_mod.unescape(title.strip()),
                               "date": d.isoformat()}
                added += 1

        nxt = None
        anchor = NEXT_A_RE.search(html)
        if anchor:
            nxt = HREF_RE.search(anchor.group(0))
        # Done when: no next page; the whole page predates the floor; or the
        # page contributed nothing new (both category lists paginate with the
        # same content, so a stale param would loop forever otherwise).
        if not nxt or (page_dates and max(page_dates) < floor) or added == 0:
            break
        url = CATEGORY + nxt.group(1)

    out = sorted(posts.values(), key=lambda p: p["date"], reverse=True)
    json.dump(out, sys.stdout, indent=2)
    print()
    return 0 if out else 1


if __name__ == "__main__":
    sys.exit(main())
