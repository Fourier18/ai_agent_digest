"""Check a digest output directory against the output contract in digest_task.md.

Usage: python3 validate.py output/YYYY-MM-DD

Prints one line per problem. ERROR lines break the contract; WARN lines are
heuristics worth a look. Exits 0 and prints PASS when there are no errors.
"""

import json
import re
import sys
from datetime import date
from html.parser import HTMLParser
from pathlib import Path

REQUIRED = [
    "digest.html",
    "digest_briefing.html",
    "digest_briefing.md",
    "episode_focus.txt",
    "digest_meta.json",
]
CATEGORIES = {
    "product-launch",
    "research-paper",
    "infrastructure",
    "standards",
    "regulation",
    "business-with-agent-angle",
}
# Written by merge_show_bible.py between the show bible and the day's focus.
FOCUS_MARKER = "TODAY'S EPISODE FOCUS"

errors = []
warnings = []


def error(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


class Outline(HTMLParser):
    """Collects the tags and heading text the contract cares about."""

    def __init__(self):
        super().__init__()
        self.counts = {}
        self.h3 = []
        self.links = []
        self._in_h3 = False

    def handle_starttag(self, tag, attrs):
        self.counts[tag] = self.counts.get(tag, 0) + 1
        if tag == "h3":
            self._in_h3 = True
            self.h3.append("")
        if tag == "a":
            self.links.append(dict(attrs).get("href", ""))

    def handle_endtag(self, tag):
        if tag == "h3":
            self._in_h3 = False

    def handle_data(self, data):
        if self._in_h3:
            self.h3[-1] += data


def norm(title):
    return " ".join(title.split())


def parse_html(path, name):
    text = path.read_text(encoding="utf-8")
    if not text.lstrip().lower().startswith("<!doctype html>"):
        error(f"{name}: must start with <!DOCTYPE html>")
    outline = Outline()
    outline.feed(text)
    if outline.counts.get("script"):
        error(f"{name}: contains <script>")
    if outline.counts.get("link") or outline.counts.get("img"):
        error(f"{name}: contains external <link> or <img>")
    if outline.counts.get("style", 0) != 1:
        error(f"{name}: needs exactly one <style> block")
    for href in outline.links:
        if not href.startswith(("http://", "https://")):
            error(f"{name}: link is not an absolute URL: {href!r}")
    return text, outline


def check_digest(path, day):
    text, outline = parse_html(path, "digest.html")
    stories = len(outline.h3)
    if not 8 <= stories <= 10:
        error(f"digest.html: {stories} stories (<h3>), need 8-10")
    sections = outline.counts.get("section", 0)
    if not 2 <= sections <= 5:
        error(f"digest.html: {sections} <section>s, need 2-5")
    if "AI Agent News Digest" not in text:
        error("digest.html: missing 'AI Agent News Digest' header")
    if day not in text:
        error(f"digest.html: date {day} not found")
    return stories, [norm(t) for t in outline.h3]


def check_briefing_html(path, day):
    text, outline = parse_html(path, "digest_briefing.html")
    if len(outline.h3) != 5:
        error(f"digest_briefing.html: {len(outline.h3)} stories (<h3>), need exactly 5")
    if outline.counts.get("section"):
        error("digest_briefing.html: must not use <section>s")
    if "AI Agent Daily Briefing" not in text:
        error("digest_briefing.html: missing 'AI Agent Daily Briefing' header")
    if day not in text:
        error(f"digest_briefing.html: date {day} not found")
    return [norm(t) for t in outline.h3]


def check_briefing_md(path, day):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0].strip() != "# AI Agent Daily Briefing":
        error("digest_briefing.md: first line must be '# AI Agent Daily Briefing'")
    if day not in text:
        error(f"digest_briefing.md: date {day} not found")
    if text.lstrip().startswith("---"):
        error("digest_briefing.md: has frontmatter")
    if "```" in text:
        error("digest_briefing.md: has code fences")
    if re.search(r"</?[a-zA-Z][^>]*>", text):
        error("digest_briefing.md: contains HTML tags")
    titles = [norm(l[3:]) for l in lines if l.startswith("## ")]
    if len(titles) != 5:
        error(f"digest_briefing.md: {len(titles)} stories (## headings), need exactly 5")
    # Each story block needs a Sources: list with at least one link.
    blocks = re.split(r"^## ", text, flags=re.M)[1:]
    for i, block in enumerate(blocks, 1):
        if "Sources:" not in block:
            error(f"digest_briefing.md: story {i} has no 'Sources:' line")
        if not re.search(r"^- \[[^\]]+\]\(https?://[^)]+\)", block, flags=re.M):
            error(f"digest_briefing.md: story {i} has no '- [title](url)' source")
    return titles


def check_focus(path):
    text = path.read_text(encoding="utf-8")
    # After merge_show_bible.py runs, only the part after the marker is the
    # agent's own writing; the show bible above it is Markdown on purpose.
    if FOCUS_MARKER in text:
        text = text.split(FOCUS_MARKER, 1)[1]
    body = text.strip()
    if not body:
        error("episode_focus.txt: empty")
        return
    for line in body.splitlines():
        if re.match(r"\s*(#|[-*+] |\d+\. )", line) or "**" in line:
            error(f"episode_focus.txt: Markdown formatting in line: {line.strip()[:60]!r}")
            break
    if re.search(r"</?[a-zA-Z][^>]*>", body):
        error("episode_focus.txt: contains HTML tags")
    sentences = len(re.findall(r"[.?!](\s|$)", body))
    if not 4 <= sentences <= 6:
        warn(f"episode_focus.txt: roughly {sentences} sentences, spec says 4-6")


def check_meta(path, day, full_count, md_titles):
    try:
        meta = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        error(f"digest_meta.json: invalid JSON: {e}")
        return
    d = meta.get("digest")
    if not isinstance(d, dict):
        error("digest_meta.json: missing 'digest' object")
        return
    if d.get("title") != "AI Agent Daily Briefing":
        error("digest_meta.json: digest.title must be 'AI Agent Daily Briefing'")
    if d.get("date") != day:
        error(f"digest_meta.json: digest.date is {d.get('date')!r}, expected {day!r}")
    if not isinstance(d.get("generated_at"), str) or not d["generated_at"]:
        error("digest_meta.json: digest.generated_at missing")
    if full_count is not None and d.get("full_story_count") != full_count:
        error(
            f"digest_meta.json: full_story_count is {d.get('full_story_count')!r}, "
            f"digest.html has {full_count}"
        )
    if d.get("briefing_story_count") != 5:
        error("digest_meta.json: briefing_story_count must be 5")
    if d.get("files") != {
        "full_digest_html": "digest.html",
        "briefing_html": "digest_briefing.html",
        "briefing_markdown": "digest_briefing.md",
        "episode_focus": "episode_focus.txt",
        "metadata": "digest_meta.json",
    }:
        error("digest_meta.json: digest.files does not match the contract")

    stories = meta.get("briefing_stories")
    if not isinstance(stories, list) or len(stories) != 5:
        n = len(stories) if isinstance(stories, list) else "no"
        error(f"digest_meta.json: {n} briefing_stories, need exactly 5")
        return
    for i, s in enumerate(stories, 1):
        where = f"digest_meta.json: briefing_stories[{i - 1}]"
        if s.get("id") != i:
            error(f"{where}: id is {s.get('id')!r}, expected {i}")
        if md_titles and i <= len(md_titles) and norm(s.get("title", "")) != md_titles[i - 1]:
            error(f"{where}: title does not match digest_briefing.md story {i}")
        try:
            date.fromisoformat(s.get("event_date", ""))
        except (TypeError, ValueError):
            error(f"{where}: event_date {s.get('event_date')!r} is not YYYY-MM-DD")
        tags = s.get("tags")
        if not isinstance(tags, list) or not 2 <= len(tags) <= 5:
            error(f"{where}: needs 2-5 tags")
        if s.get("category") not in CATEGORIES:
            error(f"{where}: category {s.get('category')!r} not allowed")
        if not s.get("one_line_summary"):
            error(f"{where}: one_line_summary missing")
        sources = s.get("primary_sources")
        if not isinstance(sources, list) or not sources:
            error(f"{where}: primary_sources missing")
            continue
        for src in sources:
            if not str(src.get("url", "")).startswith(("http://", "https://")):
                error(f"{where}: source url {src.get('url')!r} is not absolute")
            if not isinstance(src.get("is_primary"), bool):
                error(f"{where}: is_primary must be true or false")
        if not any(src.get("is_primary") is True for src in sources):
            error(f"{where}: no source has is_primary = true")


def main():
    if len(sys.argv) != 2:
        print("usage: python3 validate.py output/YYYY-MM-DD")
        return 2
    out = Path(sys.argv[1])
    day = out.name
    try:
        date.fromisoformat(day)
    except ValueError:
        error(f"directory name {day!r} is not a YYYY-MM-DD date")

    present = {p.name for p in out.iterdir()} if out.is_dir() else set()
    for name in REQUIRED:
        if name not in present:
            error(f"missing file: {name}")
    for name in sorted(present - set(REQUIRED)):
        error(f"extra file not allowed: {name}")

    full_count = digest_titles = brief_titles = md_titles = None
    if "digest.html" in present:
        full_count, digest_titles = check_digest(out / "digest.html", day)
    if "digest_briefing.html" in present:
        brief_titles = check_briefing_html(out / "digest_briefing.html", day)
    if "digest_briefing.md" in present:
        md_titles = check_briefing_md(out / "digest_briefing.md", day)
    if "episode_focus.txt" in present:
        check_focus(out / "episode_focus.txt")
    if "digest_meta.json" in present:
        check_meta(out / "digest_meta.json", day, full_count, md_titles)

    if brief_titles is not None and md_titles is not None and brief_titles != md_titles:
        error("digest_briefing.html and digest_briefing.md titles differ or are in a different order")
    if digest_titles is not None and md_titles:
        for t in md_titles:
            if t not in digest_titles:
                warn(f"briefing story not found verbatim in digest.html: {t!r}")

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if errors:
        print(f"FAIL ({len(errors)} errors)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
