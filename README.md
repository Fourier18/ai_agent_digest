# AI Agent News Digest

A daily research pipeline that produces a curated digest of AI agent news, optimized for both personal reading and feeding into Google NotebookLM for audio-overview generation.

Runs on the Anthropic **Pro subscription** via the Claude Code CLI — no per-token API costs.

## What it does

Each morning, double-clicking `run_digest.bat` invokes Claude Code to:

1. Search the web for AI agent stories from the last 24-48 hours (≥5 distinct queries: product launches, research papers, benchmarks, criticism, regulation)
2. Filter results against two strict gates:
   - **Agent relevance** — story must be primarily about agents (products, capabilities, infrastructure, benchmarks, regulation). Generic IPO/earnings/hire/fundraise news is rejected unless it explicitly signals an agent strategy shift.
   - **Primary source** — every story must cite at least one primary source (company blog, official announcement, arxiv paper, major newswire, or reputable specialist outlet). Aggregator roundup blogs alone do not qualify.
3. Produce five output files (see Outputs below)

## Use case — daily morning workflow

1. Read `digest.html` over coffee for breadth (8-10 stories across themes)
2. Upload `digest_briefing.md` + `show_bible.md` as sources in a fresh NotebookLM notebook
3. Click Audio Overview → Customize
4. Set Length to **Short**, paste contents of `episode_focus.txt` into the focus textbox
5. Generate — expect a ~6-8 minute spoken briefing

Planned future stages (not in this repo): audio → video → YouTube → social fan-out.

## Files

### Source files (versioned)

| File | Role |
|---|---|
| `run_digest.bat` | Windows double-click launcher |
| `run_digest.ps1` | Main pipeline. Locates `claude.exe`, unsets `ANTHROPIC_API_KEY` (forces subscription auth), invokes Claude Code with the prompt below. |
| `show_bible.md` | Persistent show identity for NotebookLM — host personalities, episode structure, tone targets, forbidden patterns. Edit by hand when identity needs to evolve. Re-uploaded with each new notebook. |
| `README.md` | This file. |
| `.gitignore` | Excludes regenerated outputs. |

### Daily outputs (regenerated, gitignored)

| File | Purpose |
|---|---|
| `digest.html` | Full reading digest, 8-10 stories grouped into 2-5 themes, self-contained HTML. |
| `digest_briefing.html` | Browser-preview version of the briefing — 4 stories, flat list ordered by impact. |
| `digest_briefing.md` | Same content as above in Markdown, for direct upload to NotebookLM. |
| `episode_focus.txt` | Plain-text steering prompt for NotebookLM's "What should the AI hosts focus on" textbox. Tailored to that day's specific stories. |
| `digest_meta.json` | Structured catalog of the briefing — story titles, tags, categories, primary-source URLs, `is_primary` flags. For downstream tooling. |

## Quality controls baked into the prompt

- Story must pass agent-relevance and primary-source gates
- Briefing = exactly **4** most impactful stories (NOT 3, NOT 5)
- Full digest summaries: 3-5 original sentences each
- Briefing summaries: 4-6 information-dense sentences (preserved depth, NOT truncated — NotebookLM needs material to discuss substantively)
- Primary-source rule enforced structurally via `is_primary` boolean in the JSON
- "Strict file output contract" section explicitly forbids file renames, scope creep, and divergent outputs

## Running it

1. Double-click `run_digest.bat` (or invoke `run_digest.ps1` from a PowerShell prompt)
2. Wait ~1-2 minutes while the agent researches and writes
3. The five outputs land in this folder
4. Open `digest.html` in a browser to start reading

## Model pinning and instruction-following history

The script is pinned to **Opus** (`--model claude-opus-4-7`) because the
default Claude Code model (Sonnet 4.6 at time of writing) was observed
to take creative liberties despite explicit constraints. Past
divergences included:

- Renaming `digest_briefing.html` to `digest_email.html` (and later
  `email.html`), and `digest_briefing.md` to `digest_brief.md` or
  `briefing.md`
- Inventing unrequested outputs that anticipated downstream stages
  discussed elsewhere in the project (`audio_script.txt`,
  `social_posts.txt`) — Sonnet appeared to read the project's broader
  workflow context as license to start building toward inferred goals
- Producing 5 stories in the briefing instead of the 4 required by spec
- Skipping required files (`episode_focus.txt`, `digest_meta.json`)

In addition to pinning Opus, the prompt itself was refactored to be
purely declarative — all "why" context (NotebookLM workflow, planned
video/social pipeline, audience targeting) was moved into PowerShell
comments at the top of `run_digest.ps1`, which the human reader sees
but the agent never does. This removes the contextual narrative that
Sonnet was using to justify divergences.

If your CLI does not accept the pinned model name, run
`claude --model help` to see valid identifiers and update the
invocation accordingly.

## Cost model

The script explicitly unsets `ANTHROPIC_API_KEY` so Claude Code falls back to the user's Pro subscription login. No per-token API charges. The only cost is the Pro subscription itself.

## NotebookLM integration notes

NotebookLM exposes three steering channels, in roughly descending priority:

1. **The "What should the AI hosts focus on" textbox** (`episode_focus.txt` feeds this) — highest-priority, injected directly into the orchestration prompt
2. **The Length control** (Short / Default / Long) — Short targets ~5-10 min on briefing-sized material
3. **Source documents** (`digest_briefing.md` + `show_bible.md`) — provide factual content plus persistent style/identity guidance

NotebookLM has a strong house style and certain rhetorical patterns it cannot be fully steered away from. Show bible "forbidden patterns" reduce frequency, not occurrence.
