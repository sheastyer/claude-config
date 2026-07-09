# Model selection — cost vs. capability

Match the model to the task. Over-powered models waste money at up to 10× the
rate; under-powered ones fail the task. This applies to **two** decisions: the
model *you're* running on (you can't switch it yourself, but you can alert me),
and the model you pick when spawning subagents (you choose that directly).

## The tiers (input / output per 1M tokens)

| Tier | Model | Price | Use for |
|---|---|---|---|
| 1 | **Haiku 4.5** | $1 / $5 | Mechanical, well-specified, low-judgment work: formatting, renaming, simple search/grep, boilerplate, single-file trivial edits, straightforward lookups, log scanning. |
| 2 | **Sonnet 5** | $3 / $15 | The default workhorse. Most coding, multi-file edits, standard debugging, test writing, routine refactors, code review. Near-Opus quality on coding/agentic at a fraction of the cost. |
| 3 | **Opus 4.8** | $5 / $25 | Genuinely hard work: subtle bugs, complex architecture, tricky migrations, long-horizon autonomous runs, cases where correctness matters more than cost. |
| 4 | **Fable 5** | $10 / $50 | Reserve for the most demanding reasoning and long-horizon agentic work that Opus can't handle. 2× Opus's price — rarely the right default. |

Rule of thumb: **start at Sonnet 5 and justify moving up**, not down. If you
can't articulate why a task needs Opus or Fable, it probably doesn't.

## Model vs. effort — two different levers

Per the Claude Code team's guidance, model and effort control different things:

- **Model = what Claude knows** (capability). Swapping the model swaps which
  frozen weights answer — how much knowledge and reasoning it brings.
- **Effort = how hard Claude tries** (thoroughness). It controls how much work
  Claude does: how much it thinks, how many files it reads, how much it verifies,
  and how far it pushes a multi-step task before checking in. Higher effort =
  more tokens of work; it shapes token spend but doesn't cap it (`max_tokens`
  does).

Mental model: **Fable = the specialist** you call when everyone else is stuck
(spots what no one else would; most expensive — save it for that). **Opus = the
expert** who brings outside experience and patterns not in your codebase.
**Sonnet = a really strong generalist** — great at coding, reads everything,
thorough. Effort decides how much time any of them spends. *Opus at low effort* ≈
five focused minutes with an expert; *Sonnet at high effort* ≈ a generalist with
the whole afternoon who reads and verifies everything.

**When something goes wrong, check context before touching either setting** — a
vague prompt, missing tools, or a missing skill is the usual culprit. If context
was good and it still failed, diagnose which lever: *did it not know enough
(→ larger model) or not try hard enough (→ higher effort)?* Routine work: both
models get it right and the larger one just costs more — drop down. Genuinely
hard multi-step work: the larger model reaches the bar in fewer steps, so total
cost per task can be **lower**, and it can finish tasks a smaller one can't.

## Prompting me about my own model

You cannot change the model this session runs on — only I can, via `/model`.
At the **first substantive task** of a session, quickly self-assess: if the task
sits **one or more tiers below** the model I'm running on (e.g. routine coding on
Opus when Sonnet would do, or a one-line fix on Fable), **stop and ask me** which
model to use before starting the work. Ask a short question offering two paths:

- **Continue on the current model** — proceed with the task as-is.
- **Switch to <the cheaper tier that fits>** — since you can't change the model
  yourself, tell me to run `/model sonnet` (or `haiku`/`opus`) and re-send the
  request; then wait.

Include the rough cost delta so the choice is informed (e.g. "you're on Opus at
$5/$25 per 1M tokens; Sonnet 5 at $3/$15 would handle this"). Recommend the
cheaper option as the default, but let me decide.

Ask **once per session** — if I choose to continue, don't ask again unless the
workload's demands change materially (e.g. we move from trivial edits to a hard
debugging session that now justifies the model).

Do **not** ask when the model matches or under-matches the task, or when I've
already chosen the model for this work in this session.

## Choosing a model for subagents

When you spawn a subagent (the `model` parameter on the Agent tool: `haiku`,
`sonnet`, `opus`, `fable`), pick the **lowest tier that can do the sub-task** —
independent of what model you're running on:

- **Default subagents to `sonnet`.** It handles the large majority of delegated
  work (searching, reading, editing, test runs) well.
- **Use `haiku`** for cheap, high-fan-out, mechanical sub-tasks (grep across many
  files, collecting simple facts, bulk trivial edits).
- **Use `opus`** only when the sub-task itself needs hard reasoning.
- **Never spawn `fable` subagents** unless the sub-task genuinely requires
  Fable-level reasoning — which, for a delegated sub-task, is almost never. A
  Fable orchestrator fanning out Fable subagents multiplies the most expensive
  rate across every branch.

Run subagents at low effort where the platform supports it — lower effort means
fewer, more-consolidated tool calls and less token spend, which suits scoped
sub-tasks.

Note: a **fork** always inherits my model and ignores a `model` override — so
model selection only applies to fresh (non-fork) subagents.
