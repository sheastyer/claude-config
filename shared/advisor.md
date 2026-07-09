# The advisor — a second opinion for hard single-thread tasks

The [`/advisor`](https://code.claude.com/docs/en/advisor) tool pairs the main
model with a stronger-or-equal advisor model that Claude consults at key moments
— before committing to an approach, when an error keeps recurring, and before
declaring a task done. The advisor sees the full conversation and returns
guidance the main model applies before continuing.

This is the **middle lever** between the other two guides:

- [[model-selection]] right-sizes the model doing the work.
- [[orchestration]] fans grunt work out to cheaper subagents — but only when the
  task actually *decomposes* into parallel pieces.
- **The advisor** is for the case in between: the main model is already
  correctly sized (e.g. Opus is genuinely warranted), the task is a **single hard
  thread** that won't split into delegatable grunt work, but plan quality drives
  the outcome. There's nothing to orchestrate, so instead of fanning out, escalate
  the *decision points* to a stronger second opinion.

## When it fits

Reach for the advisor on long, multi-step tasks where most turns are routine but
getting the plan right matters: large refactors, debugging where the same error
recurs, migrations, and work you want independently checked before it's called
done. It adds little on short tasks with nothing to plan.

Don't confuse it with the other levers:
- If the task **decomposes** into parallel sub-tasks → orchestrate ([[orchestration]]),
  don't just advise.
- If **every** turn needs the stronger model → switch the main model
  ([[model-selection]]), don't advise.
- If it's a **short** task → just do it.

## What you can do about it

Like `/model`, **you cannot enable the advisor yourself** — only I can, via
`/advisor <model>` (persists), the `--advisor` flag, or the `advisorModel`
setting. So:

- **Recommend it when the situation fits.** If we're on a long, single-thread,
  plan-sensitive task and no advisor is set, suggest I run `/advisor` and name a
  sensible pairing — briefly, once, then proceed either way.
- **Lean on it once it's enabled.** When an advisor is configured, actually
  consult it at the moments it's built for rather than pushing through alone:
  before locking in an approach, when you're stuck in an error loop, and before
  telling me a task is complete. You can also be asked to consult it in a prompt.
- **Don't follow it blindly.** If the advisor's guidance conflicts with what the
  code or a failed attempt actually shows, surface the conflict instead of
  applying it — same adversarial habit as [[pre-commit-review]].

## Pairings (advisor must be ≥ the main model)

- **Opus main → Opus advisor** — an independent second Opus reviews the first;
  for high-stakes work where the check matters more than cost. **→ Fable advisor**
  to escalate decision points to the specialist without paying for Fable on every
  turn.
- **Sonnet main → Opus (or Fable) advisor** — Sonnet does the routine turns and
  escalates planning, ambiguous failures, and completion checks upward.
- A cheaper main + stronger advisor typically costs **less** than running the
  stronger model throughout, because the advisor fires only at decision points.

## Cost honesty

The advisor isn't free: each call re-sends the **full transcript** to the advisor
model at its own input/output rates, and that read isn't cached (toggling the
advisor does *not* invalidate the main model's prompt cache, but the advisor
re-reads the conversation anew every call). It's cheaper than running the strong
model on every turn, not cheaper than nothing — so recommend it where the
decision quality justifies the calls, not reflexively.

Requires the Anthropic API (not Bedrock/Vertex/Foundry) and Claude Code v2.1.98+
(Fable as advisor needs v2.1.170+).
