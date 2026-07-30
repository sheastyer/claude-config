# Model selection — cost vs. capability

On the Pro subscription, **Opus 5 is the session model and the ceiling** — there
is no higher tier to escalate to and no cheaper session model worth switching to
mid-stream (a model switch invalidates the prompt cache). The two decisions that
remain: which model each **subagent** runs on, and how much **effort** the task
gets.

## The tiers (input / output per 1M tokens)

| Tier | Model | Price | Use for |
|---|---|---|---|
| 1 | **Haiku 4.5** | $1 / $5 | Mechanical, well-specified, low-judgment work: formatting, simple search/grep, boilerplate, bulk trivial edits, log scanning. |
| 2 | **Sonnet 5** | $3 / $15 (intro $2 / $10 through 2026-08-31) | The default subagent workhorse. Most delegated coding, searching, reading, test runs, routine review. |
| 3 | **Opus 5** | $5 / $25 | The session model. Hard reasoning, agentic and long-horizon work, coding. |

## Model vs. effort — effort is now the primary lever

- **Model = what Claude knows; effort = how hard it tries.** With the session
  model fixed at Opus 5, per-task cost is tuned with effort, not model swaps.
- Opus 5 at `low`/`medium` effort punches well above prior models' weight
  (per Anthropic's migration guidance). Keep the default (`xhigh`) for coding
  and hard agentic work; drop effort for routine sessions to stretch the Pro
  usage window.
- When something goes wrong, check context first (vague prompt, missing tools,
  missing skill) — then ask: did it not try hard enough (→ raise effort) before
  assuming a capability gap.

## Choosing a model for subagents

Pick the **lowest tier that can do the sub-task** (the `model` parameter on the
Agent tool):

- **Default subagents to `sonnet`.** It handles the large majority of delegated
  work well — and at intro pricing it's currently even cheaper.
- **Use `haiku`** for cheap, high-fan-out, mechanical sub-tasks.
- **Use `opus`** only when the sub-task itself needs hard reasoning — rare for a
  well-scoped delegation. Never `fable` — it isn't on this plan.
- **Always pass an explicit `model`.** Subagents default to `inherit`, which
  silently runs every worker at the session's Opus rate. (Forks always inherit
  and ignore the override — model choice applies to fresh subagents only.)
- Run subagents at **low effort** — fewer, more-consolidated tool calls suit
  scoped sub-tasks.
