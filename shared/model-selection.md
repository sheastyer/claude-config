# Model selection — cost vs. capability

On the Max subscription, **Opus is the session model** — the right default for
coding and agentic work, and there's no cheaper session model worth switching to
mid-stream (a model switch invalidates the prompt cache). **Fable is available
above it** for the rare task that earns it (below). The decisions that remain:
which model each **subagent** runs on, and how much **effort** the task gets.

## The tiers (input / output per 1M tokens)

| Tier | Model | Price | Use for |
|---|---|---|---|
| 1 | **Haiku 4.5** | $1 / $5 | Mechanical, well-specified, low-judgment work: formatting, simple search/grep, boilerplate, bulk trivial edits, log scanning. |
| 2 | **Sonnet 5** | $3 / $15 (intro $2 / $10 through 2026-08-31) | The default subagent workhorse. Most delegated coding, searching, reading, test runs, routine review. |
| 3 | **Opus 5** | $5 / $25 | The session model. Hard reasoning, agentic and long-horizon work, coding. |
| 4 | **Fable 5.1** | $10 / $50 | Most capable model. Independent high-stakes review (security/design sign-off), the hardest reasoning, problems Opus has already failed on. Long turns; 2× Opus pricing. |

## Model vs. effort — effort is now the primary lever

- **Model = what Claude knows; effort = how hard it tries.** With the session
  model fixed at Opus 5, per-task cost is tuned with effort, not model swaps.
- Opus 5 at `low`/`medium` effort punches well above prior models' weight
  (per Anthropic's migration guidance). Keep the default (`xhigh`) for coding
  and hard agentic work; drop effort for routine sessions to stretch the Max
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
  well-scoped delegation.
- **Use `fable`** only for work where an independent, strongest-available
  judgment is the point — e.g. an adversarial security/design review before
  sign-off — or when I ask for it. It costs 2× Opus and draws down the usage
  window fastest, so give it a precise brief and a stop condition (e.g. max
  review rounds), and never use it for routine delegation.
- **Always pass an explicit `model`.** Subagents default to `inherit`, which
  silently runs every worker at the session's Opus rate. (Forks always inherit
  and ignore the override — model choice applies to fresh subagents only.)
- Run subagents at **low effort** — fewer, more-consolidated tool calls suit
  scoped sub-tasks.
