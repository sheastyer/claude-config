# Git & PR workflow

These rules apply to any task that involves writing code in a git repository.
Skip them only for read-only work (questions, exploration, analysis) where no
branch or commit is produced.

## 1. Start from the latest main

Before writing any code, sync with the remote so you never build on a stale base
(e.g. a PR I merged after a previous agent's session):

1. `git fetch origin`
2. Identify the default branch (usually `main`; confirm with
   `git symbolic-ref refs/remotes/origin/HEAD` if unsure).
3. Base new work on the freshly-fetched default branch:
   - New work → create a branch from `origin/main`.
   - Continuing on an existing branch → rebase it onto `origin/main`
     (`git rebase origin/main`) and mention if that pulled in new commits.

If `git fetch` reveals the local checkout was behind, say so briefly so I know
the base moved.

## 2. Open a PR early, as a draft

Don't wait until the work is "done" to create the PR — lost worktrees and
unpushed branches are a real problem.

- As soon as there is a branch with at least one meaningful commit, push it and
  open a **draft** PR: `gh pr create --draft --fill` (write a real title/body
  rather than relying on `--fill` once there's enough to describe).
- **Draft = "in progress."** This is the signal that the PR is not ready for me
  to merge yet.
- Include a short checklist in the PR body of what's done and what's left.
- **Before pushing more commits to an existing PR's branch, confirm the PR is
  still open** (`gh pr view <number> --json state`). If it was merged or closed
  since the last push, don't push to the dead branch — start a fresh branch off
  the updated default branch and open a new PR for the follow-up.

## 3. Flip to "ready" when finished

- When the work is complete and checks are green, mark it ready for review:
  `gh pr ready <number>`.
- **Ready-for-review (non-draft) = "finished"** — these are the ones I should be
  looking at to merge.
- If a repo has `in-progress` / `ready` (or similar) labels, apply them too as a
  redundant visible signal; otherwise draft vs. ready is the source of truth.

## 4. Definition of done — never leave work stranded

Before you consider a coding task complete or end the session, verify **all** of:

- [ ] All changes are committed (no dirty working tree, no forgotten files),
      each commit having passed adversarial pre-commit review (see
      `pre-commit-review.md`).
- [ ] The branch is pushed to `origin`.
- [ ] A PR exists (draft or ready as appropriate).
- [ ] You have reported the PR URL back to me in your final message.

If any of these is missing, do it before finishing. If you genuinely cannot
(e.g. no remote configured), state clearly that the work is only local and where
the branch/worktree lives so it doesn't get lost.

## Enforcement hooks

Parts of this workflow are enforced deterministically by hooks in
`~/.claude/hooks/` (wired in `settings.json`), not just by this prose:

- `git-safety.sh` (PreToolUse) blocks commits made directly on `main`/`master`,
  force-pushes that touch them, and commits whose staged diff hasn't passed
  adversarial review (see `pre-commit-review.md` for recording the approval).
  Its block messages explain the compliant path and the deliberate overrides
  (`CLAUDE_ALLOW_MAIN=1`, `CLAUDE_SKIP_REVIEW=1`).
- `stop-done-check.sh` (Stop) blocks ending the turn once per new commit state
  when the branch has unpushed Claude-authored commits — push and open the PR,
  or report exactly where the work lives.
