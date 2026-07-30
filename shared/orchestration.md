# Orchestrator / subagent delegation

Opus 5 reaches for subagents readily — the failure mode to guard against is
**over-delegation, not reluctance**. Every subagent is its own conversation:
it re-establishes context, re-explores, reports back, and then the orchestrator
re-reads the report. That multiplies token spend and latency, and on the Pro
subscription it all draws down the same usage window. Delegate rarely and only
when the payoff clearly exceeds that overhead.

## When to delegate

**Do** use subagents for:
- Genuinely independent, sizeable, parallelizable tracks — wide multi-file
  investigations, unrelated modules, bulk mechanical sweeps.
- Side-tasks whose intermediate output I'll never look at again (the subagent
  test: "will I need the tool output, or just the conclusion?").

**Do NOT** use subagents for:
- Work finishable directly in a handful of tool calls — a few reads, a few
  edits, a simple search.
- **Review, verification, or double-checking your own work.** Verification
  belongs in the main loop; Opus 5 self-verifies without scaffolding.
  (Independent checks that exist for *fresh perspective* are different: the
  adversarial pre-commit reviewer ([[pre-commit-review]]) and a workflow's
  verify wave both stand.)
- Splitting one modest job into pieces so it *looks* parallel.

**Caps:** if one subagent suffices, use one. Keep spawn counts low; never more
than 20 parallel agents unless I explicitly ask for that scale.

## How to delegate

- Spawn **fresh** subagents with an explicit cheaper `model` per
  [[model-selection]] — `sonnet` default, `haiku` for mechanical fan-out.
  Without the override, workers silently inherit the session's Opus rate.
- Brief precisely **once** — the specific subtask, constraints it can't infer,
  where to look, and exactly what to return (a summary, a diff, a verdict).
  Avoid launch → wait → re-brief cycles.
- **Commit to the delegation.** Don't redo the subagent's work or re-derive its
  findings once it reports back. (Results that feed a commit still go through
  the pre-commit review gate — that's the checkpoint, not ad-hoc re-derivation.)
- Independent subtasks spawn **in parallel, in one message**. Never let two
  subagents edit the same file.
- Run subagents at low effort.

## Large fan-out — native workflows

For work beyond what one conversation can coordinate (codebase-wide audits,
large migrations, cross-checked research), say "use a workflow" (or `ultracode`)
or run `/deep-research` rather than hand-spawning dozens of agents. Route
grunt-work stages to cheaper models, prefer a verify wave for results that feed
decisions, and give workflows an explicit token budget in the prompt. The
standing test before any of this: parallelism must *earn its coordination cost*
— an ordinary coding task does not need a panel of five reviewers.
