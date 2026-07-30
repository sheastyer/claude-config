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
   missing/weak tests, and unintended behavior changes. **Tell it to report every
   issue it finds — including ones it's uncertain about or considers low-severity
   — with a confidence level and estimated severity per finding, and not to
   self-filter for importance** (current models follow "only report serious
   issues" so literally that real findings get silently dropped; you triage
   severity when addressing the comments, not the reviewer when writing them).
   It must end with an explicit verdict:
   - `APPROVE`, or
   - `CHANGES REQUESTED` + a numbered list of the blocking comments (the full
     findings list, blocking and not, still gets reported above the verdict).

4. **Address every comment.** Fix the code (or, if you disagree, reply with a
   concrete rebuttal). Then **re-review**: send the updated staged diff back to the
   same reviewer via `SendMessage` so it can verify its comments were resolved.

5. **Loop until `APPROVE`.** Only then run `git commit`. (One find → fix →
   re-check round is usually enough; if the reviewer is still finding new
   blocking issues after two rounds, step back and reconsider the change rather
   than grinding the loop.)

6. **Record the approval for the commit gate.** A `PreToolUse` hook
   (`~/.claude/hooks/git-safety.sh`) blocks `git commit` until the hash of the
   approved staged diff is on file. After the reviewer's `APPROVE`, run:

   ```bash
   gitdir=$(git rev-parse --absolute-git-dir) && mkdir -p "$gitdir/claude" && \
   git diff --staged | (shasum -a 256 2>/dev/null || sha256sum) | awk '{print $1}' \
     > "$gitdir/claude/review-approved"
   ```

   then commit **without touching the staged diff** — any change to it
   invalidates the approval, which is the point: the recorded hash is proof
   that exactly this diff was reviewed. For the trivial non-code commits this
   guide already exempts, bypass the gate deliberately with
   `CLAUDE_SKIP_REVIEW=1 git commit ...` (and still say so when you skip).

## Reporting
When you commit, briefly note that the adversarial review passed and summarize
what it flagged and how you resolved it, so I can see what changed as a result.
