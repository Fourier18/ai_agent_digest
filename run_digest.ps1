# Daily AI Agent News Digest — runs via Claude Code (uses your Pro subscription, not API credits).
#
# Usage:
#   .\run_digest.ps1
#
# When it finishes, open digest.html in this folder.

# Force subscription auth. If ANTHROPIC_API_KEY is set in your environment,
# Claude Code uses that and bills per token — unset it for this process.
$env:ANTHROPIC_API_KEY = $null

# Always write digest.html into this script's folder, regardless of where it was launched.
Set-Location -Path $PSScriptRoot

# Locate claude.exe. Anthropic's Claude Code desktop installer puts it under
# %APPDATA%\Claude\claude-code\<version>\ but doesn't add it to PATH.
# Pick the highest installed version automatically.
$claude = $null
$claudeBase = Join-Path $env:APPDATA "Claude\claude-code"
if (Test-Path $claudeBase) {
    $latest = Get-ChildItem $claudeBase -Directory -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -as [version] } |
              Sort-Object { [version]$_.Name } -Descending |
              Select-Object -First 1
    if ($latest) {
        $candidate = Join-Path $latest.FullName "claude.exe"
        if (Test-Path $candidate) { $claude = $candidate }
    }
}
# Fall back to PATH if Anthropic ever changes the install layout.
if (-not $claude) {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) { $claude = $cmd.Source }
}
if (-not $claude) {
    Write-Error "Could not find claude.exe. Searched $claudeBase and PATH."
    exit 1
}
Write-Host "Using: $claude`n"

$today = Get-Date -Format "yyyy-MM-dd"

$prompt = @"
You are a tool-using agent. Your job is to call tools to create a file.
Your text response is irrelevant; only the file on disk matters.

Today's date is $today.

Required tool calls, in order:

1. WebSearch — call at least 5 times with DIFFERENT queries covering
   recent AI agent news (product launches, research papers,
   benchmarks, criticism, regulation). Focus on stories from the
   last 24-48 hours. After identifying candidate stories, search
   again for the PRIMARY source of each (company blog, paper,
   official announcement, major newswire) — aggregator roundups
   alone are not enough.

2. WebFetch — call as needed to read full articles. Use it
   especially to confirm a primary source actually says what an
   aggregator claims, and to write substantive summaries.

Story selection rules (apply STRICTLY — drop stories that fail any):
- The story must be primarily about AI agents: agent products,
  agent capabilities, agent infrastructure, agent benchmarks,
  agent regulation, or research that directly changes what agents
  can do. Generic company news (IPO filings, earnings, executive
  hires, fundraises) does NOT qualify on its own — only include
  it if the story is explicitly about the company's agent
  strategy or an agent product, and frame the summary around
  that agent angle. When in doubt, drop it.
- Each story must cite at least one PRIMARY source: the
  publisher's own site or blog, the company's own announcement,
  a paper on arxiv, a major newswire (Reuters/Bloomberg/AP/
  Financial Times), or a reputable specialist outlet (TechCrunch,
  The Information, Stratechery, The Verge, Ars Technica). Daily
  AI-news roundup blogs do NOT count as a primary source; they
  may appear as additional sources but never as the only source.

3. Write — call EXACTLY FIVE TIMES, in this exact order, with these
   EXACT filenames. Filenames are NOT suggestions and NOT a starting
   point for your own naming choices. DO NOT rename them. DO NOT
   abbreviate them. DO NOT substitute synonyms (no "email" for
   "briefing", no "brief" for "briefing", no "summary" for "briefing").
   DO NOT create any additional files not listed here.

   First Write call (full digest, for personal reading):
     file_path: digest.html
     content: <full self-contained HTML file per "Full digest
     specification" below>

   Second Write call (short briefing as HTML):
     file_path: digest_briefing.html
     content: <tight briefing HTML per "Briefing specification" below>

   Third Write call (same briefing as Markdown, for NotebookLM upload):
     file_path: digest_briefing.md
     content: <markdown version of the briefing per "Briefing Markdown
     specification" below>

   Fourth Write call (today's customization-box prompt for NotebookLM):
     file_path: episode_focus.txt
     content: <plain-text focus prompt per "Episode focus
     specification" below>

   Fifth Write call (structured metadata for downstream tooling):
     file_path: digest_meta.json
     content: <JSON metadata per "JSON metadata specification" below>

4. After ALL FIVE Write calls succeed, respond with one short line
   such as:
   "Saved digest.html (7 stories), digest_briefing.html,
   digest_briefing.md (4 stories), episode_focus.txt, and
   digest_meta.json."

STRICT FILE OUTPUT CONTRACT — read before doing anything in step 3:
- Exactly 5 files must be written, with the EXACT filenames listed
  above. No more files, no fewer. No renames, no creative variants.
- The briefing files (digest_briefing.html, digest_briefing.md, and
  the briefing_stories array in digest_meta.json) MUST contain
  EXACTLY 4 stories. Not 3. Not 5. Four. Before writing the briefing
  files, count your selected stories. If the count is anything other
  than 4, revise your selection until it is 4.
- All five Write tool calls in step 3 are MANDATORY. If you do not
  call all five, you have failed the task. If you write files not in
  this list (no "_email", no "_brief", no "_summary" variants), you
  have failed the task. If you write the same file twice with
  different content, you have failed the task.
- Do NOT include HTML, Markdown, or JSON in your text response. All
  content belongs in the Write content arguments, nowhere else.

Full digest specification:
- HTML5 doctype, <html lang="en">
- All CSS inline in a single <style> block. No external scripts, fonts,
  stylesheets, or images.
- max-width around 760px centered, line-height around 1.6, system font
  stack, generous whitespace
- Header: <h1>AI Agent News Digest</h1> and the date $today
- 2-5 themed <section>s, each starting with <h2> of the theme name
- Each story: <h3>title</h3>, <p>3-5 sentence original summary</p>,
  "Sources:" followed by <ul><li><a href="..." target="_blank"
  rel="noopener noreferrer">title</a></li>...</ul>
- At most 10 stories total. At most 5 sources per story. Fewer is fine.
- No JavaScript, no emoji, quiet professional tone

Summaries in the full digest must be 3-5 original sentences explaining
what happened and why it matters — not headline rephrasing. Quality over
quantity: if only 4 stories are genuinely noteworthy, ship 4.

Briefing specification:
- This is a tight subset of the full digest, intended to be fed to a
  podcast-style audio generator (NotebookLM) for a 6-8 minute spoken
  briefing. Same research, sharper selection, SAME prose depth.
- Pick the 4 MOST IMPACTFUL agentic stories from the full digest.
  "Most impactful" = the stories that most directly change what agents
  can do, how agents are built, or the competitive landscape for agent
  builders. Cut financial/business stories unless they explicitly
  signal a strategic agent shift. When in doubt, cut.
- Audio length is controlled by NUMBER of stories, not by per-story
  brevity. The audio generator will discuss the source material, so
  each story needs enough factual content for substantive discussion.
  Do NOT shorten summaries. If anything, the briefing benefits from
  richer per-story context than the full digest, because fewer stories
  means the hosts can go deeper on each one.
- Same HTML style block and overall structure as the full digest, but:
    * Header: <h1>AI Agent Daily Briefing</h1> and the date $today
    * NO theme <section>s — just a flat list of 4 stories ordered by
      impact (most important first)
    * Each story: <h3>title</h3>, <p>full summary of equal or greater
      depth than the full digest's version — 4-6 information-dense
      sentences covering what happened, the key technical/strategic
      details, and why it matters for agent builders</p>, sources list
      (same format as the full digest)
- Same primary-source rule applies — every briefing story must cite at
  least one primary source.
- Goal: give the audio generator enough factual material that the two
  hosts can discuss the actual data substantively, without needing to
  invent filler.

Briefing Markdown specification:
- Plain Markdown, no HTML tags, no frontmatter, no code fences around
  the document.
- Identical content to digest_briefing.html — same 4 stories, same
  order, same paragraph depth, same primary-source list per story.
- Structure:
    # AI Agent Daily Briefing
    $today

    ## <story 1 title>
    <4-6 sentence summary paragraph>

    Sources:
    - [<source title>](<url>)
    - [<source title>](<url>)

    ## <story 2 title>
    ...
- The Markdown file is the one uploaded to NotebookLM; it must read
  cleanly as a standalone document with no styling required.

Episode focus specification:
- Plain text only. NO Markdown formatting — no headings, no bullet
  lists, no bold or italic. NO HTML. Just sentences.
- This text is pasted directly into NotebookLM's "What should the AI
  hosts focus on in this episode?" textbox. It is a high-priority
  steering prompt for the audio generator. It is NOT part of the
  source corpus.
- 4-6 sentences total. Declarative phrasing throughout. Tailored
  specifically to the four stories in TODAY's briefing.
- The content MUST include all of the following:
    * Which of the four stories should lead the episode, and a one-
      clause reason ("lead with X because it is the structural piece
      that the other three depend on").
    * One specific point where the two hosts should disagree — drawn
      from a real tension in today's source material, not manufactured
      drama. Phrase it as a question the hosts hold different
      positions on.
    * One framing or pattern to avoid for this particular day's
      content (e.g., "do not frame this as a Google vs. OpenAI
      horse-race"; "do not treat the funding announcement as the lead").
    * Optional but encouraged: one technical detail worth dwelling
      on because it has architectural implications for agent builders.
- A persistent show identity file (show_bible.md) defines the host
  personalities and episode format. Do NOT redefine those here. The
  episode focus layers on top of the show bible, it does not replace
  it.
- Information-dense. No hedging. No filler phrases. No closing
  pleasantries.

JSON metadata specification:
- Valid JSON. No trailing commas. No JavaScript-style comments.
- Captures structured metadata about the day's briefing for use by
  downstream tooling (cataloging, analytics, future pipeline stages).
- Required top-level structure (this exact shape, these exact keys):
    {
      "digest": {
        "title": "AI Agent Daily Briefing",
        "date": "$today",
        "generated_at": "<ISO 8601 timestamp at time of generation>",
        "full_story_count": <integer, total stories in digest.html>,
        "briefing_story_count": 4,
        "files": {
          "full_digest_html": "digest.html",
          "briefing_html": "digest_briefing.html",
          "briefing_markdown": "digest_briefing.md",
          "episode_focus": "episode_focus.txt",
          "metadata": "digest_meta.json"
        }
      },
      "briefing_stories": [ <exactly 4 story objects> ]
    }
- Each entry in briefing_stories MUST have this exact shape:
    {
      "id": <integer 1 through 4, in order of impact>,
      "title": "<story title, matching digest_briefing.md>",
      "event_date": "<YYYY-MM-DD of the underlying news event>",
      "tags": ["<short topic tags, 2-5 entries>"],
      "category": "<one of: product-launch, research-paper,
        infrastructure, standards, regulation, business-with-agent-angle>",
      "one_line_summary": "<single declarative sentence, no markdown>",
      "primary_sources": [
        {
          "url": "<full URL>",
          "title": "<source title>",
          "is_primary": <true if a primary source per the rules
                         above, false if aggregator/secondary>
        }
      ]
    }
- briefing_stories MUST contain exactly 4 entries — the same 4
  stories as digest_briefing.md, in the same impact order, with
  matching titles.
- At least one entry in each story's primary_sources array MUST have
  is_primary = true (this enforces the primary-source rule at the
  data layer as well as in prose).
"@

& $claude -p $prompt `
    --allowedTools "WebSearch,WebFetch,Write,Read" `
    --permission-mode acceptEdits `
    --output-format text
