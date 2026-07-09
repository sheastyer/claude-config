---
name: claude-code-blog-sync
description: >-
  Scan the official Claude Code blog (https://claude.com/blog-category/claude-code)
  for new posts, digest them with cheap subagents, and propose concrete updates to
  this claude-config repo (shared/*.md conventions, settings.json, skills) for the
  user to approve before anything is applied — including retiring existing
  conventions that newer guidance or model capabilities have made obsolete. Use
  this whenever the user asks to check the Claude Code blog, pull the latest
  Claude Code best practices, "sync" or "update" their conventions/workflow from
  Anthropic's guidance, prune outdated practices, or asks "anything new in Claude
  Code?" — even if they don't name the blog explicitly. Also the right skill for
  scheduled/recurring best-practice checks.
---

# Claude Code blog sync

Keep this config repo current with Anthropic's published Claude Code guidance,
without re-reading everything each time and without applying anything the user
hasn't approved.

The repo this skill maintains is a dotfiles-style config symlinked into
`~/.claude/`: `CLAUDE.md` thinly `@`-imports one convention per file from
`shared/`, `settings.json` holds defaults, and skills live under `skills/`.
Read `README.md` at the repo root first if you are unfamiliar with the layout.

## Why the process looks like this

- **State file** — the blog accumulates; without a record of what was already
  reviewed (and what the user declined), every run re-proposes the same things.
- **Cheap subagents for reading** — fetching whole posts into an expensive
  main-model context burns money on grunt work. Digest at Sonnet rates; decide
  at the main model.
- **Approval gate** — this repo *is* the user's global agent behavior. Silent
  edits here change how every future session acts. Nothing lands without an
  explicit yes.

## Workflow

### 1. Load state

Read `state.json` in this skill's directory. It records every post previously
seen and its disposition. If it doesn't exist (first run), treat all posts as
new but check `shared/*.md` before proposing — several older posts are already
incorporated there.

### 2. Fetch the index

Run the bundled scraper (plain HTTP — the page's "View more" button is
server-side Webflow pagination, so no browser is needed, but a single
WebFetch of the category page sees only the first ~15 posts and silently
misses the rest):

```bash
python3 scripts/fetch_index.py --floor <YYYY-MM-DD>
```

It walks every page and prints `{url, title, date}` for each post at or
after the floor, newest first. Pick the floor so the same articles aren't
re-scraped run after run:

- **Normal run:** `last_checked` from `state.json` minus ~30 days (the
  overlap is cheap insurance against edited/backdated posts; the state check
  below dedupes it).
- **First run or explicit backfill:** the script's default floor,
  `2025-11-01` — the hard limit on how far back this skill ever looks.

Posts in `state.json` with a settled disposition are skipped — including
`declined` (do not re-propose declined items unless the user asks to revisit
them). Posts marked `proposed`
carry an undecided proposal from a previous run: re-surface it in this run's
summary rather than re-digesting the post.

### 3. Digest new posts with cheap subagents

Never fetch full post content in the main context. Spawn fresh
`general-purpose` subagents with an explicit `model: sonnet` (never inherit —
that silently runs workers at the orchestrator's rate), batching 2–4 posts per
agent, launched in parallel in one turn. Ask each for, per post:

- Core thesis (1–2 sentences)
- Concrete recommendations / decision rules (precise; quote key phrasing)
- New features or commands mentioned
- Anything actionable for a personal Claude Code config repo

Skip digestion for posts that are obviously not workflow-relevant
(hackathon winner showcases, partnership/availability announcements) — record
them in state as `irrelevant` with a one-line reason instead.

### 4. Compare against the repo and draft proposals — additions *and* retirements

Read the current `shared/*.md` files, `CLAUDE.md`, and `settings.json`. For
each digest, decide what (if anything) it changes:

- **Already covered** — the repo says the same thing; record `covered`
  with a pointer to the covering file, propose nothing.
- **Update** — the repo covers the topic but the post adds/corrects something;
  propose an edit to the existing `shared/<name>.md`.
- **New convention** — a durable cross-project practice with no home; propose
  a new `shared/<name>.md` plus its one-line `@`-import in `CLAUDE.md`
  (keep `CLAUDE.md` thin; one convention per file; cross-link with `[[name]]`).
- **New skill / settings change** — repeatable procedures become a skill under
  `skills/`; configuration becomes a `settings.json` edit.
- **Retire** — existing repo guidance that newer material has made obsolete:
  a workaround for a model limitation that no longer exists, a practice a
  newer post walks back or supersedes, or a feature/command that was renamed
  or removed. Propose deleting or pruning the stale text, citing the newer
  source. Removing a whole `shared/<name>.md` guide also removes its
  `CLAUDE.md` import line (`shared/` is linked as one directory, so
  `install.sh` is untouched); removing a whole skill also removes its
  per-skill `install.sh` `ITEMS` entry.

Then make one deliberate staleness pass in the other direction: sweep the
existing `shared/*.md` guides against everything digested this run and ask
of each convention, "does anything newer supersede this?" A useful lens
(from "Improving skill-creator", Mar 2026): classify each guide or skill as
**capability uplift** (techniques that beat the base model — these decay as
models improve and deserve the retirement scrutiny) or **encoded
preference** (the user's own workflow and conventions — durable as long as
they track the real process). Additions get
proposed every run by default; retirements only happen if something actively
looks for them, so a config repo naturally accretes. The pass surfaces
*candidates*; a candidate becomes a retirement proposal only once matched to
a citable source — a post digested this run, or a changelog/release-note URL
fetched to confirm the capability shift. Record source-backed retirements in
`state.json` keyed by the citing document's URL (the schema takes any URL,
not just blog posts) so a declined retirement is never re-proposed; a hunch
with no source stays a note in the run summary, not a proposal.

Hold a high bar in both directions: this file set loads into *every*
session, so each addition taxes all future context — prefer tightening an
existing guide over adding a new one, and skip anything speculative,
redundant, or product-marketing-shaped. And prune on evidence, never on the
vibe that "models are better now" — that's the difference between pruning a
repo and hollowing it out.

### 5. Present proposals and get approval

Show the user a numbered summary — for each proposal: the source post (title +
date + URL), the one-paragraph takeaway, and the specific change (which file,
roughly what text). Present retirements alongside additions, quoting the text
that would be removed and the newer source that supersedes it. Then ask which to apply (AskUserQuestion with multiSelect
works well; include a "none" path). **Do not make any behavior-changing edit
(`shared/*.md`, `CLAUDE.md`, `settings.json`, `install.sh`, skills) before
this approval.** `state.json` is exempt from the gate — it's bookkeeping, not
behavior: on an unattended run (scheduled/background), stop after producing
the summary, but still record `covered`/`irrelevant` verdicts, mark undecided
items `proposed`, and advance `last_checked`, so the next run doesn't re-read
the whole backlog.

### 6. Apply approved changes and record state

Apply only the approved proposals, following this repo's own conventions
(they're loaded in context: fresh branch off `origin/main`, adversarial
pre-commit review before committing, push, draft PR, report the PR URL).
If a new top-level file/dir must reach `~/.claude/`, add it to the `ITEMS`
array in `install.sh` and mention that `./install.sh` needs a re-run.

Update `state.json` in the same commit — every post seen this run gets an
entry with its disposition, plus date and a one-line note. Set `last_checked`
to today. Update state even on a run that proposes nothing, so the next run
skips what this one already read.

## state.json format

```json
{
  "last_checked": "2026-07-08",
  "posts": {
    "https://claude.com/blog/example-post": {
      "title": "Example post",
      "published": "2026-06-18",
      "disposition": "incorporated",
      "note": "folded into shared/model-selection.md"
    }
  }
}
```

Dispositions: `incorporated` (an approved change was applied because of this
post), `covered` (repo already said it — nothing was changed), `declined`
(user said no — never re-propose), `irrelevant` (no workflow content —
skipped without digestion), `proposed` (proposal made, user hasn't decided —
re-surface next run without re-digesting). Keeping `incorporated` and
`covered` distinct preserves the audit trail of what this skill actually
changed versus what was already true.

## Gotchas

- Never inventory the blog with a bare WebFetch of the category page — it
  returns only the first page (~15 posts) and there is no signal that more
  exist beyond a JS "View more" button. `scripts/fetch_index.py` follows the
  underlying `?<listid>_page=N` pagination and is the only supported way to
  list posts.
- WebFetch returns claude.com links as relative paths (`/blog/...`) — prepend
  `https://claude.com` before storing or fetching them (the scraper already
  outputs absolute URLs).
- Subagent digests can misquote. Before an edit that hinges on a specific
  claim (a command name, a setting, a number), have the applying step verify
  it against the post rather than trusting the digest — same adversarial habit
  as pre-commit review.
- Hackathon showcases, customer case studies, and availability announcements
  look substantive in digests but rarely change a personal workflow — that's
  what the `irrelevant` fast path is for.
- The proposal summary is the deliverable, not a formality: each item needs
  the source post, the takeaway, and the exact file-level change, or the user
  can't approve it from a phone.
