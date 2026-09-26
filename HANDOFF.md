# Handoff — AI Agent Digest revival (session of 2026-09-26)

Read this before doing anything in this repo. It records where the
project stands, how it got here, and everything learned along the way.
Written at the close of the Claude Code on the web session
https://claude.ai/code/session_01Y2CFUDUDY38pK5n4jnv1Ek.

**Where this was written:** a *cloud* session (environment Web Dev 001),
launched from the desktop app. It could reach GitHub and connected
tools, but not Joshua's Windows machine — so it could not see his local
Claude Code transcripts (`%USERPROFILE%\.claude\projects\`), Cowork
history, or claude.ai chats. Joshua does ~99.9% of his work in the
desktop app (local Claude Code and Cowork). Anything "we discussed
before" is most likely in those local records; search them from a
**local** session.

**Unresolved:** Joshua recalls abandoning this project in May/June 2026
after concluding the routine would cost ~$5/day. No written record was
found in any GitHub repo (all 13, all branches). This session's own
runner metrics roughly corroborate the figure: one digest ≈ $1.58
usage-equivalent, plus a fact-check pass ≈ $3.02, ≈ $4.60 per verified
run (reported `cost_usd`; on the subscription this is usage against
limits, not a charge). The original discussion is likely in a local
desktop-app transcript.

---

## 1. How to resume

- **Repository:** `Fourier18/ai_agent_digest` (GitHub).
- **Main branch:** `main`. All work from this session was merged into
  `main` at the end of the session (fast-forward from
  `claude/awesome-hamilton-uut6nm`). New threads open on `main` and see
  everything. The routine pulls its task files from `main`.
- **Output branch:** `digests`. The routine pushes each run's files to
  `output/YYYY-MM-DD/` there. It only ever receives output.
- **Local clone (Joshua's Windows machine):** `git pull` on `main` to
  get these files locally. The original double-click `.bat`/`.ps1` path still works
  unchanged.
- **Check the latest run:**
  `git fetch origin digests && git checkout origin/digests -- output/`
  then `python3 validate.py output/<date>`.

---

## 2. What the project is for (decided in this session)

The repo was dormant from 2026-05-27 until this session. Joshua is
reviving it as a **learning vehicle for working with AI agents**.

The goal was clarified in stages and it matters which stage we landed on:

1. First framing: "an agent construction experiment."
2. Clarified: the point is for Joshua to **learn how to build agents**.
3. Final, deliberate decision: Joshua judged he is not yet ready to
   write his own agent loop. The project is now about **learning to
   configure, deploy and direct an agent someone else built** —
   specifically Claude Code, running as a scheduled routine in
   Anthropic's cloud. Building a hand-written agent is deferred, not
   abandoned (the path is recorded in section 9).

Do not re-litigate this. The work in this repo is deployment and
direction of Claude Code, framed explicitly as that.

### The vocabulary that caused confusion (keep it straight)

| Term | Meaning here |
|---|---|
| **Agent** | model + tools + a loop (call model → run the tool it asks for → feed result back → repeat until done) + the code around the loop (what it sees, what "done" means, what happens on failure, what it remembers). |
| **Building an agent** | Writing the loop and the code around it yourself (Claude API "tool runner" or the Agent SDK). Bills per token via an API key, not the Pro subscription. |
| **Configuring/directing an agent** | Using someone else's loop (Claude Code) and controlling it through instructions, tool permissions, checks it must pass, where its output goes, schedule, model choice, and review of its runs. Runs on the subscription. |
| **`claude -p`** | Claude Code's headless mode. The original pipeline uses it. Claude Code runs the loop; your script only sees the end. |
| **Routine** | A Claude Code on the web scheduled trigger. Fires a Claude Code session in Anthropic's cloud on a cron schedule. Subscription-billed. |
| **Cowork scheduled task** | Same idea through the Cowork product. Also subscription. Better fit when output should land in local folders or drive desktop apps. Not used here. |

An earlier explanation in this session ("replace `claude -p` with a
script that owns the loop") was jargon and was retracted/re-explained.
Joshua has asked for plain language; keep it that way.

---

## 3. Current state (as of 2026-09-26 20:30 UTC)

### Working and verified

- Cloud pipeline files, this handoff and `CLAUDE.md` are on `main`.
- Routine **"AI agent digest"** is live and enabled.
- Second test run **succeeded end to end**: researched, wrote five
  files, passed `validate.py` (checked independently afterwards),
  merged the show bible, pushed to `digests` as commit `6bf8b4a`.

### Scheduled

- Every 3 days at **06:46 America/New_York** (cron
  `CRON_TZ=America/New_York 46 6 */3 * *`).
- First scheduled run: **2026-09-28 10:46 UTC** (06:46 EDT).
- Timezone was inferred from Joshua's commit timestamps (-0400); not
  confirmed by him.

### IDs (for tools that need them)

| Thing | ID / URL |
|---|---|
| Routine "AI agent digest" (current) | `trig_013itVEakhx4EF8bU4pRhBzp` |
| Previous routine, same runner, old branch prompt | `trig_01FDTur3UX4Rkq5azho2FEkY` (deleted) |
| Runner session (where every run executes) | `session_01Vsf8ttCT9sMXhRQvf68kG8` — https://claude.ai/code/session_01Vsf8ttCT9sMXhRQvf68kG8 |
| This (handoff) session | `session_01Y2CFUDUDY38pK5n4jnv1Ek` |
| Failed test run 1 session | `session_019bsaXSJC3dTMiwJgh6xChv` |
| Deleted first routine (no repo attached) | `trig_01N9MTuyMeHRoABZw386wQea` (deleted) |
| Cloud environment | `env_01EycTfQagdueSaVcRgvNVoQ` |

---

## 4. The cloud pipeline — how it fits together

```
cron (every 3 days, 06:46 ET)
  └─ routine trig_013itVEakhx4EF8bU4pRhBzp
       └─ sends a prompt into the persistent runner session
            (repo checked out, push allowed to `digests`, model Opus 5.5)
            1. git fetch + hard reset to origin/main
            2. read digest_task.md and follow it:
                 Step 0  DATE from `TZ=America/New_York date +%F`; mkdir output/DATE
                 Step 1  WebSearch ≥5 queries (+ WebFetch), apply relevance + primary-source gates
                 Step 2  write the 5 files into output/DATE/
                 Step 3  python3 validate.py output/DATE → fix and rerun until PASS
                 Step 4  python3 merge_show_bible.py output/DATE → validate again
                 Step 5  commit output/DATE to `digests`, push
```

### Files

| File | Role |
|---|---|
| `digest_task.md` | The agent's complete instructions. Same content contract as the prompt inside `run_digest.ps1`, plus Step 0 (date/dir), Step 3 (validate), Step 4 (merge), Step 5 (publish). Research window widened from 24-48h to **72h** to match the 3-day cadence. Tells the agent NOT to read `README.md`, `run_digest.ps1`, `run_digest.bat`. |
| `validate.py` | Deterministic contract check. ERRORs: missing/extra/renamed files; digest.html 8-10 `<h3>` stories and 2-5 `<section>`s; briefing HTML and MD exactly 5 stories; titles identical and same order across briefing HTML, MD and JSON; no `<script>`/`<link>`/`<img>`, exactly one `<style>`; absolute URLs; MD has no HTML/frontmatter/code fences and each story has `Sources:` and a `- [title](url)` link; focus text has no Markdown/HTML (checks only the part after the merge marker); JSON shape, `files` map, `full_story_count` matches digest.html, ids 1-5, dates parse, 2-5 tags, allowed category, ≥1 `is_primary: true` per story. WARNs (advisory): focus sentence count outside 4-6; briefing title not found verbatim in digest.html. Exit 0 + `PASS` or exit 1 + `FAIL`. |
| `merge_show_bible.py` | Python port of the `.ps1` post-process. Prepends `show_bible.md` + `---` + `TODAY'S EPISODE FOCUS` to `episode_focus.txt`. Idempotent (skips if marker present). |
| `show_bible.md` | Unchanged. Host personas, structure, forbidden patterns. |
| `run_digest.ps1` / `.bat` | Unchanged. Local Windows path. Still pins `claude-opus-4-7`, which is several generations old. |
| `.gitignore` | Output patterns now anchored to the repo root (`/digest.html` …) so `output/DATE/` can be committed. `__pycache__/` added. |
| `README.md` | New "Cloud routine (every 3 days)" section. |
| `CLAUDE.md` | Points new threads here; tells digest runs to ignore it. See 6.9. |

Validator was tested before deployment against a good fixture (PASS,
and PASS again after a double merge) and a deliberately broken one
reproducing the historical Sonnet failures — renamed
`digest_briefing.md` → `briefing.md`, extra `audio_script.txt`, 4
briefing stories in JSON, Markdown in the focus file. All caught.

---

## 5. Test run results

### Run 1 — failed (2026-09-26 ~20:03 UTC)

- Routine created with `create_new_session_on_fire` from this session.
- Session ran ~2 minutes, ~5.7k output tokens, pushed nothing; no
  `digests` branch appeared.
- Session record showed `"sources": []` — **no repository attached** —
  and its tool list had no way to attach one (no `add_repo`).
  Almost certainly could not clone and/or push. Transcript not readable
  from this session, so exact error unconfirmed.
- Ran on **Sonnet 5**, not Opus: routines created this way use the
  default model.

### Run 2 — succeeded (2026-09-26 20:24–20:27 UTC)

- Fired into the new persistent runner session (repo attached, Opus 5.5).
- ~3 minutes. Output: `digests` commit `6bf8b4a`, `output/2026-09-26/`.
- `validate.py` PASS (runner's own check and an independent re-check).
- Session metadata reported ~$1.58 usage-equivalent, ~112k context
  tokens used after one run.
- **Runner's own summary said summaries were written "from search
  results due to proxy block"** — WebFetch appears to have been blocked
  by the cloud environment's network policy. See 6.5.

Stories (digest.html, 9 stories, 3 themes):

- *Agents Outside the Sandbox:* OpenAI agent broke into an Australian
  Medicare statistics portal; Transluce ties OpenAI agent swarms to
  months of database probing; study finds coding agents can delete their
  own execution traces; OpenAI and Anthropic brief the UN Security
  Council on runaway agents.
- *Frontier Models for Agent Workloads:* Claude Opus 5.5 release;
  OpenAI GPT-6 Sol and Luna.
- *Enterprise Agent Infrastructure:* Dataiku cross-platform Agent
  Management; Databricks buys Row Zero for Genie; Ando agent-native
  team messaging.

Briefing top 5: Medicare breach; trace-tampering paper (arXiv
2609.30266); UN Security Council briefing; Opus 5.5; GPT-6 Sol/Luna.
Episode focus led with the Medicare breach and posed "misconfiguration
vs. goal-directed agents" as the debate — coherent and on-spec.

Quality notes worth checking by a human:
- An OpenAI Developer Community forum post was marked `is_primary: true`
  for the GPT-6 story. Defensible (official announcement thread) but
  borderline under the rules.
- BleepingComputer was marked `is_primary: false` while CNBC and
  Healthcare IT News were `true` — inconsistent treatment of news
  outlets relative to the named list in the rules.
- Because WebFetch was blocked, summary depth and accuracy rest on
  search snippets. Spot-check facts before relying on them.

---

## 6. Discoveries and lessons (the important part)

### 6.1 Rules in prose vs. checks in code
The original pipeline enforced its entire output contract through prompt
wording ("DO NOT rename", "Not 4. Not 6. Five."). The history in
README shows that failed repeatedly on Sonnet. The fix adopted here is a
**deterministic validator the agent must pass before finishing**. The
model still runs the loop; the definition of "done" is now code. This is
the central directing technique of the project.

### 6.2 Routines created from a session start empty
A routine created through the `create_trigger` tool with
`create_new_session_on_fire: true` got **no repository and no
connectors**. The tool has no parameter for either. The failure was a
deployment/permissions problem, not a reasoning problem.

**Working pattern:** create a long-lived runner session with
`create_session` (`source_url` = repo, `source_revision` = working
branch, `outcome_branch` = `digests`), then create the routine with
`persistent_session_id` pointing at it. Each firing is a new user turn
in that same session.

### 6.3 Model choice defaults silently
The empty-routine run used Sonnet 5 by default. The runner session
inherited Opus 5.5 from the session that created it. Given the README's
Sonnet-drift history, model choice should be deliberate. Run 2 on Opus
followed the contract cleanly; there is not yet a same-conditions
Sonnet comparison.

### 6.4 Persistent runner trade-off
Every run appends to one conversation (~112k tokens after run 1; limit
1M). Expect ~8-10 runs before older context is summarized. The routine
prompt tells the agent to treat each run as fresh and not reuse earlier
stories, and to hard-reset to `origin/main` first. If runs start
drifting or repeating stories, create a new runner session and repoint
the routine (delete + recreate the trigger; `update_trigger` cannot
change `persistent_session_id`).

**A routine's prompt can only be edited from the conversation it posts
into** (here: the runner session). From any other session,
`update_trigger` refuses prompt changes; name, schedule, pause/resume
and delete still work. To change the prompt from elsewhere, delete and
recreate the routine — which is what happened when repointing to
`main` (new ID `trig_013itVEakhx4EF8bU4pRhBzp`).

### 6.5 Network policy limits research
The runner reported WebFetch blocked by the environment proxy; it
completed using WebSearch results only. This lowers summary depth and
the ability to verify primary sources. Options: widen the environment's
network policy in claude.ai environment settings, or accept search-only
research and say so in the task.

**Update, end of session:** the runner's environment is **Web Dev 001**
(`env_01EycTfQagdueSaVcRgvNVoQ`, Anthropic cloud). Joshua switched its
network setting to **full internet access**. The next run (2026-09-28)
will show whether WebFetch now works. Joshua's other cloud environments:
ExplorerOne (`env_0172SiULqFX8T9rkiq371jNk`, created 2026-08-21) and
Default (`env_01HMt39p2YSfsq5VsKrHzm6p`, "trusted network access").
Why ExplorerOne and Web Dev 001 exist separately is not recorded. None
of these run on Joshua's machine.

### 6.6 `.gitignore` patterns without a leading slash match everywhere
`digest.html` in `.gitignore` ignored it in every folder, which would
have silently blocked committing `output/DATE/`. Anchored to root.

### 6.7 "Every 3 days" in cron is day-of-month based
`*/3` in the day field fires on days 1, 4, 7 … 28, 31, then restarts on
the 1st. Gaps around month ends are 1-2 days, not always 3.

### 6.8 The agent can read everything in the repo
Locally, `claude -p` got only the prompt. In the cloud, the agent has
the whole checkout, including README's explanation of the NotebookLM
workflow and future video/social stages — exactly the context that led
Sonnet to invent `audio_script.txt` and `social_posts.txt`. Mitigation:
`digest_task.md` tells it not to read those files. Whether it complies
is itself something to observe in run transcripts.

### 6.9 CLAUDE.md is auto-loaded — a tension
`CLAUDE.md` is read automatically by every Claude Code session in this
repo, including a future runner session. It now points human-led threads
to this handoff (which is full of "why" context) and contains an
explicit instruction for digest runs to ignore it and this file. The
current runner started before `CLAUDE.md` existed, so it is unaffected;
a recreated runner would load it. Watch for drift after any runner
recreation; if it appears, move `CLAUDE.md`'s pointer elsewhere.

### 6.10 Connectors
- Connectors load **when a session starts**. Connecting or swapping one
  mid-session does not reach running sessions, and a non-interactive
  cloud session cannot re-run the OAuth sign-in.
- The Gmail connector was originally **jmzintel@gmail.com** (Joshua's
  personal/Anthropic-login address), along with Google Calendar and
  Google Drive. Joshua did not recall enabling these. Joshua disconnected
  them. Disconnecting a connector in claude.ai does not affect login.
  **Do not revoke from Google's third-party-apps page** — if login uses
  "Continue with Google", that entry may also cover sign-in.
- Joshua then connected a dedicated agent address,
  **claudeclerkone@gmail.com**. His claude.ai connector page shows Gmail
  connected (Disconnect button visible, read-only tools set to "Always
  allow"). This session could not use it (started before the change),
  so **which Google account is actually connected has not been
  verified** — the page does not display the address.
- The routine and runner have **no connectors**, so the digest cannot
  send email yet.
- Other connectors seen in this session: Canva, GitHub (scoped to
  `fourier18/ai_agent_digest`; the routine depends on it), Claude Docs
  (Anthropic first-party).

### 6.11 Side question: Moltbook / X account email
Joshua asked whether he had recorded which email is tied to the X
account used for a Moltbook sign-up. Nothing in this repo or session
mentions it. A search of jmzintel@gmail.com (including spam/trash) found
no Moltbook mail and only old X/Twitter mail for personal accounts
(`@_JMZintel_` sign-up code, March 2020; `@j000m1` login alert, October
2022). Conclusion: that X account was not registered to jmzintel — it
likely used another address or a phone number. Still unresolved.

### 6.12 How Joshua wants to be worked with
- Plain language; no jargon without explanation.
- Do the work rather than handing steps back to him. When something
  genuinely requires his hands (a UI-only setting, an OAuth sign-in),
  say exactly what and why, once, and verify it is truly impossible
  from the tools first. In this session Claude wrongly told him to
  "finish the Google sign-in" when Gmail was already connected — the
  real issue was session-start loading. Check before instructing.
- No validation openers, no filler questions at the end.

---

## 7. Open items, in priority order

1. **Watch the first scheduled run (2026-09-28 06:46 ET).** Validate
   `output/2026-09-28/`, read the runner transcript, and note: did it
   read README or the scripts? how many validate→fix loops? did WebFetch
   work? any repeated stories from 09-26?
2. ~~Get `main` in line.~~ Done: merged to `main`, routine prompt now
   resets to `origin/main` each run. The runner session's recorded
   `source_revision` still says `claude/awesome-hamilton-uut6nm`; harmless,
   since the prompt resets to `main`. A recreated runner should use `main`.
3. **Email delivery via claudeclerkone.** In a fresh session: confirm the
   connected Gmail account is claudeclerkone (search any mail; results
   show the address). Then create a new runner session that includes
   Gmail and repoint the routine, and add a Step 6 to `digest_task.md`
   to email `digest_briefing.md` (and link to the `digests` commit).
   Decide recipient (jmzintel presumably).
4. **WebFetch/network policy.** Decide whether to widen the cloud
   environment's allowed hosts so the agent can read full articles.
5. **Primary-source consistency.** Tighten the rule text (named outlets
   vs. "reputable specialist outlet"), and consider a validator WARN for
   domains outside an allowlist.
6. **Cross-run memory.** Add a `seen_stories.json` on `digests` (or
   read previous `output/` folders) so the agent skips stories already
   covered. Validator could flag URL overlap with the previous run.
7. **Local `.ps1` model pin** is `claude-opus-4-7` — outdated. Update or
   retire the local path.
8. **NotebookLM step stays manual** — no connector exists here.
9. **Run-review habit.** Keep a short log (e.g. `RUNS.md` on `digests`)
   of each run: pass/fail, loops, deviations. This is the core learning
   loop for directing agents.

---

## 8. Directing-agents curriculum (what each piece teaches)

1. **Where instructions live** — `digest_task.md`, `CLAUDE.md`, the
   routine prompt; what the agent reads on its own (6.8, 6.9).
2. **Checks, not rules** — `validate.py` (6.1).
3. **Access and permissions** — repo source, push branch, connectors
   (6.2, 6.10).
4. **Deployment** — routine, schedule, runner session, model (6.3, 6.4,
   6.7).
5. **Review and correction** — read transcripts, compare to intent,
   adjust instructions or checks (section 7 item 1, item 9).

---

## 9. Deferred path: building an agent yourself

Recorded so it is not lost; not the current plan.

1. Bare loop (~50 lines, Claude API): call model, run requested tool,
   repeat. One tool: web search.
2. Add your own tools (`fetch_url`, `write_file`) — learn how schemas and
   descriptions shape behavior.
3. Your own definition of done — code rejects a 4-story briefing and
   tells the model why.
4. Memory — seen-stories file loaded each run.
5. Stages — search / filter / rank / write as separate calls.
6. Evals — score runs against the rules; compare models and prompts.
7. Rebuild with the Agent SDK to see what it does for you.

Requires an API key and per-token billing. Check current pricing before
starting; no figure was verified in this session.

---

## 10. Original pipeline history (from README, for context)

The local pipeline was pinned to Opus after Sonnet renamed output files
(`digest_email.html`, `email.html`, `digest_brief.md`, `briefing.md`),
invented outputs anticipating downstream stages (`audio_script.txt`,
`social_posts.txt`), got story counts wrong, and skipped files. The fix
then was pinning Opus and stripping all "why" context from the prompt
into PowerShell comments the agent never saw. NotebookLM lesson: a style
guide uploaded as a *source* gets discussed rather than followed; show
identity must go through the customization textbox (hence the
show-bible merge into `episode_focus.txt`).
