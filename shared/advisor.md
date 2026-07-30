# The advisor — a clean-context second opinion

The [`/advisor`](https://code.claude.com/docs/en/advisor) tool pairs the session
with an advisor model consulted at key moments — before committing to an
approach, when the same error keeps recurring, and before declaring a task done.
The advisor reads the full conversation in a fresh context and returns guidance.

**Pairing on this setup: Opus 5 main → Opus 5 advisor** (`/advisor opus`) — an
independent second Opus, free of the session's anchoring. The advisor must be ≥
the main model, and Opus 5 is the ceiling on Pro, so this is the pairing.

## When it fits

Long, single-thread, plan-sensitive tasks: large refactors, migrations,
debugging where the same failure recurs, and work worth an independent check
before it's called done. If the task *decomposes* into parallel pieces,
orchestrate instead ([[orchestration]]); if it's short, just do it.

## What you can do about it

- **Only I can enable it** (`/advisor opus`; it persists once set). Suggest it
  once when the situation fits, then proceed either way.
- **Once enabled, actually consult it** at the moments above rather than
  pushing through alone.
- **Don't follow it blindly** — if its guidance conflicts with what the code or
  a failed attempt shows, surface the conflict.

## Cost honesty

Each call re-sends the full transcript to the advisor, uncached, at Opus rates —
and on Pro that draws down the same usage window as the session itself. Reserve
it for genuinely hard problems and suggest turning it off when the task ends.
Requires the Anthropic first-party backend and Claude Code v2.1.98+.
