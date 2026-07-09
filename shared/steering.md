# Steering — where an instruction belongs

When adding a convention or automation, pick the mechanism by what the thing
*is* — a fact, a procedure, a guarantee, or a side-task — not by habit. The
wrong home either taxes every session's context or fails exactly when it
matters. (Source: Anthropic's "Steering Claude Code" and "How we use skills"
posts, June 2026.)

## The decision table

| The instruction is… | Put it in… | Why |
|---|---|---|
| A fact every session needs (build commands, layout, team norms) | `CLAUDE.md` | Always loaded, re-read after compaction — but every line costs tokens whether or not it's relevant. Keep it under ~200 lines. |
| A procedure or runbook (multi-step workflow, checklist) | A **skill** | Only name + description load at start; the body loads when invoked. A 30-line procedure in CLAUDE.md is the canonical anti-pattern. |
| Something that must happen deterministically ("always X after Y", "never Z") | A **hook** | Prose rules can fail under pressure or prompt injection; hooks are enforced by the harness. A `PreToolUse` hook can inspect and block a tool call. |
| Relevant to only part of a codebase | A **rule** (`.claude/rules/` with a `paths:` glob) | Unscoped rules behave like CLAUDE.md and leak tokens into unrelated work. |
| A side-task whose intermediate output I'll never reference again (deep search, log analysis, audits) | A **subagent** | Runs in an isolated context; only the final message returns to the main thread. |

Output styles carry the highest instruction-following weight of any mechanism
but *replace* the default coding instructions unless frontmatter sets
`keep-coding-instructions: true` — check the built-ins (Proactive,
Explanatory, Learning) before writing a custom one.

## Writing skills well

- One category per skill — a skill that straddles several confuses the agent.
- Write the `description` for the *model's* discovery decision, not for
  humans: include the trigger phrases users actually say.
- Don't restate what the model already knows; spend the lines on what pushes
  it off its default behavior, and keep a "gotchas" section for known failure
  points. Avoid railroading — leave room to adapt.
- Bundle scripts and templates so turns go to composition, not boilerplate;
  persist state in JSON or append-only logs next to the skill.
- Guardrails you don't want globally can ship as skill-scoped hooks that
  activate only while the skill runs (Anthropic's `/careful` blocks
  destructive commands; `/freeze` restricts edits to named directories).

Verification skills — encoding "how to check this worked" with measurable
criteria — showed the biggest quality gains of any category in Anthropic's
internal use. When a workflow keeps getting hand-verified, that's the skill
to write first.

See [[orchestration]] for when the answer is "a subagent", and
[[model-selection]] for which model that subagent should run on.
