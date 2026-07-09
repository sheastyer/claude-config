# Orchestrator / subagent delegation

On **complex, multi-part tasks**, don't do everything yourself on one model.
Act as an **orchestrator**: keep the high-judgment work on the capable model
running this session, and fan the grunt work out to fresh subagents on cheaper
models. This is the pattern the Claude Code team recommends (a Fable/Opus
orchestrator that plans and delegates to Sonnet workers) and Claude Code ships
natively (dynamic workflows, per-subagent models); the rules below make me use it
by default. See [[model-selection]] for the cost tiers and [[pre-commit-review]]
for the adversarial-verification habit this builds on.

**Orchestration needs a task that *decomposes*.** If the work is a single hard
thread with no grunt work to fan out, don't force a subagent split — reach for
the [[advisor]] instead (escalate the decision points to a stronger second
opinion). Orchestrate when there are parallel pieces; advise when there aren't.

**Why this saves money:** the orchestrator's own token count stays small — it
plans, delegates, and synthesizes — while the workers generate the bulk of the
tokens at the cheaper worker rate. Most of the spend lands at the worker price,
not the orchestrator's. That only holds if the workers are actually on a cheaper
model (see the `inherit` trap below).

## The split

**Keep on the orchestrator (the capable session model — Fable/Opus):**
- The plan and the decomposition itself.
- Architectural and judgment calls, trade-off decisions.
- Integrating subagent results and making the final decisions.
- The final answer, and anything that needs the full conversation context.

**Delegate to cheaper subagents:**
- File discovery, code search, reading many files (→ `haiku`/`sonnet`).
- Mechanical edits repeated across files, boilerplate drafting.
- Running tests / builds and collecting output.
- Independent investigations that only need to return a summary.

## How to delegate

- Spawn **fresh** subagents (not forks — a fork inherits my model and ignores a
  `model` override) via the Agent tool, and **pass an explicit cheaper `model`**
  per the tiers in [[model-selection]]: `haiku` for mechanical fan-out, `sonnet`
  as the default worker, `opus` only when a subtask genuinely needs hard
  reasoning, never `fable`.
- **Why the explicit model matters:** Claude Code subagents default to
  `inherit` — without an override they run on *my* model. So a Fable/Opus
  orchestrator that doesn't set a cheaper `model` silently runs every subagent
  at the orchestrator's rate, which is exactly the cost trap to avoid.
- Run independent subtasks **in parallel** (spawn them in one turn) and let the
  orchestrator synthesize.
- Prime each subagent minimally — the specific subtask, the constraints it
  can't infer, and where to look — not the whole conversation.
- **Verify what matters.** For delegated results that feed a decision or a
  commit, verify adversarially before trusting them (same habit as
  [[pre-commit-review]]) — re-derive rather than taking the summary at face value.

## Large fan-out — use native dynamic workflows

For work that needs **more agents than one conversation can coordinate**
(codebase-wide audits, large migrations, cross-checked research), reach for
Claude Code's dynamic workflows instead of hand-spawning agents: say "use a
workflow" (or `ultracode`) in the request, or run the bundled `/deep-research`.
The runtime fans out dozens–hundreds of subagents in the background, keeps
intermediate results out of my context, and is resumable.

- When I author a workflow, **route grunt-work stages to a cheaper model** — the
  script can send different stages to different models, and workflow agents
  otherwise default to the session's model.
- Prefer the two-wave shape where it fits: workers produce results, then a
  second wave adversarially verifies them before they're reported.

## Named workflow patterns

Seven shapes worth asking for by name (from Anthropic's dynamic-workflows
post, June 2026). They exist to counter three failure modes of long
single-context runs — agentic laziness (stopping early), self-preferential
bias (favoring your own output when judging it), and goal drift (compaction
eroding the original requirements):

- **Classify-and-act** — route each item by type before working on it.
- **Fan-out-and-synthesize** — parallel workers, merged structured outputs.
- **Adversarial verification** — a separate agent checks each worker's output
  against a rubric (the two-wave shape above).
- **Generate-and-filter** — produce many candidates, dedupe/filter by rubric.
- **Tournament** — N agents attempt the same task, judged pairwise;
  comparative judgment is more reliable than absolute scoring. Also the fix
  for sorting/ranking at scale, where single-prompt quality degrades past
  ~1000 rows.
- **Loop-until-done** — iterate on a stop *condition*, not a fixed pass count
  (pair `/loop` with `/goal` for continuous triage; see [[loops]]).
- **Quarantine** — agents that read untrusted content get no high-privilege
  actions; separate agents act on the vetted results.

Give workflows an explicit token budget in the prompt ("use ~10k tokens") to
cap spend. And the standing test before reaching for any of these:
parallelism and specialization have to *earn their coordination cost* — most
ordinary coding tasks do not need a panel of five reviewers.

## Cost discipline

Fan-out multiplies token spend — each subagent is its own conversation. Delegate
when the task's size justifies it; for a small or trivial task, just do it
directly on the current model. Match the effort to the subtask: run subagents at
low effort so they make fewer, more-consolidated tool calls.
