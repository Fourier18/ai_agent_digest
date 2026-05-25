# ============================================================
# AI Agent News Digest — Daily Pipeline
# ============================================================
#
# Runs via Claude Code on Anthropic Pro subscription (NOT API credits).
#
# WORKFLOW CONTEXT (for the human reading this — the prompt below is
# kept strictly declarative and does NOT include any of this rationale.
# Sonnet has been observed using contextual narrative as license to
# "improve" the design — renaming files to fit the implied use case,
# inventing extra outputs for downstream stages, ignoring story-count
# constraints when the broader story suggested more would help.):
#
#   1. Run this script (or double-click run_digest.bat).
#   2. Read digest.html over coffee for breadth.
#   3. Upload digest_briefing.md + show_bible.md as sources to a fresh
#      Google NotebookLM notebook.
#   4. Click Audio Overview -> Customize. Set Length to Short. Paste
#      contents of episode_focus.txt into the focus textbox.
#   5. Generate audio overview (~6-8 min spoken briefing).
#
# FILE ROLES (outputs produced by this script):
#   digest.html          Full reading digest, 8-10 stories, themed
#   digest_briefing.html 4 most impactful stories, browser preview
#   digest_briefing.md   Same 4 stories as Markdown for NotebookLM
#   episode_focus.txt    Steering prompt for NotebookLM focus textbox
#   digest_meta.json     Structured catalog for downstream tooling
#
# MODEL PINNING:
#   The script pins to Opus because Sonnet has been observed taking
#   creative liberties despite explicit constraints. If your CLI does
#   not recognize the model name in the invocation below, run
#   `claude --model help` (or `claude /model` inside an interactive
#   session) to list valid identifiers and update accordingly.
#
# Usage:
#   .\run_digest.ps1   (or double-click run_digest.bat)
#
# When it finishes, open digest.html in this folder.
# ============================================================

# Force subscription auth. If ANTHROPIC_API_KEY is set in your env,
# Claude Code uses that and bills per token — unset it for this process.
$env:ANTHROPIC_API_KEY = $null

# Always write outputs into this script's folder, regardless of where
# it was launched.
Set-Location -Path $PSScriptRoot

# Locate claude.exe. Anthropic's Claude Code desktop installer puts it
# under %APPDATA%\Claude\claude-code\<version>\ but doesn't add it to
# PATH. Pick the highest installed version automatically.
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
You are a tool-using agent. Your job is to call tools to create files.
Your text response is irrelevant; only the files on disk matter.

Today's date is $today.

Required tool calls, in order:

1. WebSearch — call at least 5 times with DIFFERENT queries covering
   recent AI agent news (product launches, research papers,
   benchmarks, criticism, regulation). Focus on stories from the last
   24-48 hours. After identifying candidate stories, search again for
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

3. Write — call EXACTLY FIVE TIMES, in this order, with these exact
   filenames. Filenames are NOT suggestions. DO NOT rename. DO NOT
   abbreviate. DO NOT substitute synonyms (no "email", no "brief", no
   "summary", no "script", no "posts", no "transcript"). DO NOT
   create files not on this list.

   1. digest.html
   2. digest_briefing.html
   3. digest_briefing.md
   4. episode_focus.txt
   5. digest_meta.json

4. After all five Write calls succeed, reply with exactly:
   "Saved 5 files."

STRICT FILE OUTPUT CONTRACT:
- Exactly 5 files written. Exactly the names above. Exact order.
- digest.html contains 8-10 stories. digest_briefing.html,
  digest_briefing.md, and the briefing_stories array in
  digest_meta.json each contain EXACTLY 4 stories. Not 3. Not 5.
  Four. Count before writing.
- All five Write calls are MANDATORY.
- ANY file written with a different name = task failure.
- ANY extra file beyond the 5 above = task failure. This means: no
  audio scripts, no social posts, no email versions, no transcripts,
  no slide outlines, no follow-up files of any kind, regardless of
  what you infer about how these files might be used downstream.
- All content goes in Write content arguments — never in your text
  reply.

================================================================
digest.html specification:
- HTML5 doctype, <html lang="en">.
- All CSS inline in a single <style> block. No external scripts,
  fonts, stylesheets, or images.
- max-width around 760px centered, line-height around 1.6, system
  font stack, generous whitespace.
- Header: <h1>AI Agent News Digest</h1> and the date $today.
- 2-5 themed <section>s, each starting with <h2> of the theme name.
- Each story: <h3>title</h3>, <p>3-5 sentence original summary</p>,
  "Sources:" followed by <ul><li><a href="..." target="_blank"
  rel="noopener noreferrer">title</a></li>...</ul>.
- 8-10 stories total. At most 5 sources per story.
- No JavaScript, no emoji, quiet professional tone.
- Summaries: 3-5 original sentences explaining what happened and
  why it matters. Not headline rephrasing.

================================================================
digest_briefing.html specification:
- Pick the 4 MOST IMPACTFUL agentic stories from digest.html. "Most
  impactful" = the stories that most directly change what agents can
  do, how agents are built, or the competitive landscape for agent
  builders. Cut financial/business stories unless they explicitly
  signal a strategic agent shift.
- Same HTML style block and overall structure as digest.html, but:
    * Header: <h1>AI Agent Daily Briefing</h1> and the date $today.
    * NO theme <section>s — flat list of 4 stories ordered by
      impact (most important first).
    * Each story: <h3>title</h3>, <p>4-6 information-dense sentences
      covering what happened, key technical/strategic details, and
      why it matters for agent builders</p>, sources list (same
      format as digest.html).
- EXACTLY 4 stories. Same primary-source rule applies.

================================================================
digest_briefing.md specification:
- Plain Markdown, no HTML tags, no frontmatter, no code fences
  around the document.
- Identical content to digest_briefing.html — same 4 stories, same
  order, same paragraph depth, same source list per story.
- Structure:
    # AI Agent Daily Briefing
    $today

    ## <story 1 title>
    <4-6 sentence summary>

    Sources:
    - [<source title>](<url>)
    - [<source title>](<url>)

    ## <story 2 title>
    ...
- Must read cleanly as a standalone document with no styling.

================================================================
episode_focus.txt specification:
- Plain text only. NO Markdown formatting (no headings, no bullets,
  no bold). NO HTML. Just sentences.
- 4-6 declarative sentences tailored specifically to the 4 stories
  in TODAY's briefing.
- Required content (cover all four points):
    * Which of the four briefing stories should lead, plus a
      one-clause reason.
    * One specific point of disagreement to surface — drawn from a
      real tension in today's source material, not manufactured.
      Phrase as a question with two defensible positions.
    * One framing or pattern to avoid for this day's content
      (e.g., "do not frame this as a Google vs. OpenAI horse-race";
      "do not treat the funding announcement as the lead").
    * One technical detail worth dwelling on because it has
      architectural implications for agent builders.
- Information-dense. Declarative. No hedging. No filler. No closing
  pleasantries.

================================================================
digest_meta.json specification:
- Valid JSON. No trailing commas. No JavaScript-style comments.
- Required top-level structure (these exact keys):
    {
      "digest": {
        "title": "AI Agent Daily Briefing",
        "date": "$today",
        "generated_at": "<ISO 8601 timestamp>",
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
- Each entry in briefing_stories (exactly 4 entries):
    {
      "id": <integer 1-4, in order of impact>,
      "title": "<matches digest_briefing.md story title>",
      "event_date": "<YYYY-MM-DD of the underlying event>",
      "tags": ["<2-5 short topic tags>"],
      "category": "<one of: product-launch, research-paper,
        infrastructure, standards, regulation,
        business-with-agent-angle>",
      "one_line_summary": "<single declarative sentence, no markdown>",
      "primary_sources": [
        {
          "url": "<full URL>",
          "title": "<source title>",
          "is_primary": <true if a primary source per the rules
                          above, false if aggregator or secondary>
        }
      ]
    }
- At least one source per story must have is_primary = true.
"@

& $claude -p $prompt `
    --model claude-opus-4-7 `
    --allowedTools "WebSearch,WebFetch,Write,Read" `
    --permission-mode acceptEdits `
    --output-format text
