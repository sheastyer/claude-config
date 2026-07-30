---
name: loop-design
description: >-
  Pick the right primitive for recurring or goal-driven work — plain prompt vs
  /goal vs /loop vs /schedule — and define measurable stop conditions. Load when
  setting up a recurring task, a polling loop, a scheduled/cloud agent, a
  "keep going until it passes" goal, or when a loop is burning tokens without
  converging.
---

# Loops — pick the primitive, define the stop

A loop is trigger + work + stop condition. Picking the right primitive for
the trigger, and making the stop condition *measurable*, matters more than
prompting harder. (Source: "Getting started with loops", June 2026.)

| Primitive | Trigger | Stops when | Use for |
|---|---|---|---|
| Plain prompt (turn-based) | Me | Model judges it done | One-off tasks |
| `/goal` | Me | Goal met (add a try cap: "stop after 5 tries") | Work with a verifiable target |
| `/loop` | Interval, or self-paced if none given (local) | Model judges it done, or I stop it; dies with the machine | Polling, recurring local chores |
| `/schedule` | Cron or webhook/API (cloud) | Disabled | Unattended recurring work |

## Rules

- **Deterministic stop criteria, always.** Test-pass counts, score
  thresholds, explicit try caps ("get Lighthouse to 90+, stop after 5
  tries") — evaluators verify measurable criteria far more reliably than
  vibes like "until it's good".
- **Match the interval to the watched system.** Polling every 5 minutes for
  a thing that changes daily burns tokens for nothing; when the right cadence
  isn't obvious, omit the interval and let `/loop` self-pace.
- **`/loop` dies with the laptop** — anything that must run unattended
  belongs in `/schedule`.
- **Script the mechanical steps.** Running a script is cheaper than
  reasoning through the same steps every iteration; that's also what makes
  verification repeatable (encode it as a skill — see the `steering` skill).
- **Watch the meters on big runs**: `/usage` breaks token spend down by
  skill/subagent/MCP; `/workflows` shows per-agent usage and can stop
  individual agents mid-run.
- **Small tasks don't need loops.** Start with the plain prompt and add
  machinery only when the task demonstrably needs it.

Proactive automation — recurring streams of well-defined work (triage,
dependency upgrades, migrations) — is `/schedule` + `/goal` + skills
composed, with `shared/orchestration.md` patterns for the fan-out inside each
run. Pair unattended runs with auto mode (classifier-gated permissions —
safer than skipping prompts outright), preferably in an isolated environment.
