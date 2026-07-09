# Adversarial pre-commit review

**Mandatory gate: never run `git commit` on code you wrote until an adversarial
reviewer subagent has approved the diff.** This applies to every commit that
contains code changes (skip only for trivial non-code commits — docs typos,
`.gitignore` tweaks, etc., and say so when you skip).

## Procedure

1. **Stage the change** so there is a concrete diff (`git add -A` or the relevant
   paths; the reviewer looks at `git diff --staged`).

2. **Spin up a fresh subagent — at least one — on a brand-new context window.**
   Use a fresh agent (e.g. `general-purpose`), **not** a fork: the reviewer must
   *not* inherit my conversation, so it isn't anchored by your own reasoning or
   rationalizations. Prime it with the **minimum** it needs:
   - A 1–3 sentence statement of what the change is supposed to do and why.
   - Any hard constraints it can't infer (API contracts, invariants, perf/security
     requirements, "don't touch X").
   - Where the diff is (`git diff --staged`) and any commands to build/test.
   - Do **not** paste the whole conversation history or your justifications.

3. **Give it the adversarial brief.** The reviewer's job is to find what's wrong,
   not to be agreeable. Have it hunt for: correctness bugs and edge cases, broken
   assumptions, race conditions, security issues, error handling, resource leaks,
   missing/weak tests, and unintended behavior changes. It must end with an
   explicit verdict:
   - `APPROVE`, or
   - `CHANGES REQUESTED` + a numbered list of specific, blocking comments.

4. **Address every comment.** Fix the code (or, if you disagree, reply with a
   concrete rebuttal). Then **re-review**: send the updated staged diff back to the
   same reviewer via `SendMessage` so it can verify its comments were resolved.

5. **Loop until `APPROVE`.** Only then run `git commit`.

## Reporting
When you commit, briefly note that the adversarial review passed and summarize
what it flagged and how you resolved it, so I can see what changed as a result.
