# Digest task

You are a tool-using agent. Your job is to produce files on disk and
publish them. Follow these steps in order. Do not read README.md,
run_digest.ps1, or run_digest.bat; everything you need is in this file.

## Step 0 — Set up

- Get today's date in America/New_York: `TZ=America/New_York date +%F`.
  Call it DATE below.
- Output directory: `output/DATE/`. Create it. Write every file there.

## Step 1 — Research

1. WebSearch — call at least 5 times with DIFFERENT queries covering
   recent AI agent news (product launches, research papers,
   benchmarks, criticism, regulation). Focus on stories from the last
   72 hours. After identifying candidate stories, search again for
   the PRIMARY source of each.
2. WebFetch — call as needed to read full articles for substantive
   summaries and to verify primary-source claims when relying on
   aggregators.

Story selection rules (apply STRICTLY — drop any story that fails):
- Story must be primarily about AI agents: agent products, agent
  capabilities, agent infrastructure, agent benchmarks, agent
  regulation, or research that directly changes what agents can do.
  Generic company news (IPO filings, earnings, executive hires,
  fundraises) does NOT qualify on its own — only include if it
  explicitly signals an agent strategy shift, framed around that
  angle.
- Each story must cite at least one PRIMARY source: publisher's own
  site or blog, the company's own announcement, a paper on arxiv, a
  major newswire (Reuters/Bloomberg/AP/FT), or a reputable specialist
  outlet (TechCrunch, The Information, Stratechery, The Verge, Ars
  Technica). Daily AI-news roundup blogs do NOT count as primary.

## Step 2 — Write exactly these five files into output/DATE/

1. digest.html
2. digest_briefing.html
3. digest_briefing.md
4. episode_focus.txt
5. digest_meta.json

Filenames are NOT suggestions. Do not rename, abbreviate, or
substitute synonyms. Do not create any other file in output/DATE/ —
no audio scripts, social posts, email versions, transcripts, slide
outlines, or follow-up files of any kind.

### digest.html
- HTML5 doctype, `<html lang="en">`.
- All CSS inline in a single `<style>` block. No external scripts,
  fonts, stylesheets, or images.
- max-width around 760px centered, line-height around 1.6, system
  font stack, generous whitespace.
- Header: `<h1>AI Agent News Digest</h1>` and DATE.
- 2-5 themed `<section>`s, each starting with `<h2>` of the theme name.
- Each story: `<h3>title</h3>`, `<p>3-5 sentence original summary</p>`,
  "Sources:" followed by `<ul><li><a href="..." target="_blank"
  rel="noopener noreferrer">title</a></li>...</ul>`.
- 8-10 stories total. At most 5 sources per story.
- No JavaScript, no emoji, quiet professional tone.
- Summaries: 3-5 original sentences explaining what happened and why
  it matters. Not headline rephrasing.

### digest_briefing.html
- Pick the 5 MOST IMPACTFUL agentic stories from digest.html: the
  stories that most directly change what agents can do, how agents
  are built, or the competitive landscape for agent builders. Cut
  financial/business stories unless they explicitly signal a
  strategic agent shift.
- Same style block and overall structure as digest.html, but:
  - Header: `<h1>AI Agent Daily Briefing</h1>` and DATE.
  - NO `<section>`s — flat list of 5 stories ordered by impact.
  - Each story: `<h3>title</h3>`, `<p>4-6 information-dense sentences
    covering what happened, key technical/strategic details, and why
    it matters for agent builders</p>`, sources list (same format as
    digest.html).
- EXACTLY 5 stories. Same primary-source rule applies.

### digest_briefing.md
- Plain Markdown, no HTML tags, no frontmatter, no code fences.
- Identical content to digest_briefing.html — same 5 stories, same
  titles, same order, same paragraph depth, same sources.
- Structure:

      # AI Agent Daily Briefing
      DATE

      ## <story 1 title>
      <4-6 sentence summary>

      Sources:
      - [<source title>](<url>)

      ## <story 2 title>
      ...

### episode_focus.txt
- Plain text only. No Markdown, no HTML. Just sentences.
- 4-6 declarative sentences tailored to the 5 stories in the briefing,
  covering all four points:
  - Which story should lead, plus a one-clause reason.
  - One specific point of disagreement drawn from a real tension in
    the source material, phrased as a question with two defensible
    positions.
  - One framing or pattern to avoid for this episode.
  - One technical detail worth dwelling on because it has
    architectural implications for agent builders.
- Information-dense. No hedging, filler, or closing pleasantries.

### digest_meta.json
- Valid JSON with exactly this top-level shape:

      {
        "digest": {
          "title": "AI Agent Daily Briefing",
          "date": "DATE",
          "generated_at": "<ISO 8601 timestamp>",
          "full_story_count": <integer, stories in digest.html>,
          "briefing_story_count": 5,
          "files": {
            "full_digest_html": "digest.html",
            "briefing_html": "digest_briefing.html",
            "briefing_markdown": "digest_briefing.md",
            "episode_focus": "episode_focus.txt",
            "metadata": "digest_meta.json"
          }
        },
        "briefing_stories": [ <exactly 5 story objects> ]
      }

- Each story object:

      {
        "id": <1-5, in order of impact>,
        "title": "<identical to the digest_briefing.md title>",
        "event_date": "<YYYY-MM-DD>",
        "tags": ["<2-5 short topic tags>"],
        "category": "<product-launch | research-paper | infrastructure |
                     standards | regulation | business-with-agent-angle>",
        "one_line_summary": "<one declarative sentence>",
        "primary_sources": [
          { "url": "<full URL>", "title": "<title>",
            "is_primary": <true | false> }
        ]
      }

- At least one source per story must have `"is_primary": true`.

## Step 3 — Validate

Run `python3 validate.py output/DATE`.

If it prints any ERROR, fix the files and run it again. Repeat until
it exits with "PASS". Do not edit validate.py. WARN lines are advisory.

## Step 4 — Merge the show bible

Run `python3 merge_show_bible.py output/DATE`. Then run
`python3 validate.py output/DATE` once more and confirm PASS.

## Step 5 — Publish

Commit only `output/DATE/` to the branch `digests` and push it:

- If `origin/digests` exists, check it out (`git fetch origin digests`
  then `git checkout -B digests origin/digests`); otherwise create
  `digests` from the current HEAD.
- Commit message: `Digest DATE`.
- `git push -u origin digests`.

Finish by replying with one line: the validator result and the commit
hash.
