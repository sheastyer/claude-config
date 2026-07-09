#!/usr/bin/env bash
#
# Stop hook: definition-of-done guard (git-pr-workflow.md §4 — "never leave
# work stranded"). When Claude tries to end its turn while the current repo
# has UNPUSHED Claude-co-authored commits, block the stop once and feed the
# checklist back, so finished work gets pushed + PR'd (or at least reported)
# instead of dying with a lost local branch.
#
# Deliberately scoped to unpushed *commits* with a Claude trailer — not dirty
# trees or the user's own commits — so it stays quiet during normal
# conversation and mid-task edits. Fires at most once per (session, HEAD):
# committing more work re-arms it, pushing disarms it.
#
# Exit 0 lets Claude stop; exit 2 makes it continue with stderr as guidance.
# Unexpected conditions fail OPEN (exit 0).

set -u

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat) || exit 0

# Never block twice in one stop cycle (loop guard).
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1 || exit 0
head=$(git -C "$cwd" rev-parse HEAD 2>/dev/null) || exit 0
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null) || exit 0 # detached: skip

# Commits not on the upstream (preferred) or, for never-pushed branches, not
# on the remote default branch. No remote at all -> nothing to enforce here;
# the prose workflow already tells Claude to report local-only work.
if git -C "$cwd" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  range='@{u}..HEAD'
else
  defref=$(git -C "$cwd" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/||')
  [ -n "$defref" ] || exit 0
  [ "$branch" = "${defref#origin/}" ] && exit 0
  range="$defref..HEAD"
fi

unpushed=$(git -C "$cwd" log --oneline --grep='Co-Authored-By: Claude' "$range" 2>/dev/null | head -n5)
[ -n "$unpushed" ] || exit 0

marker="${TMPDIR:-/tmp}/claude-done-check-${session}-$(printf '%s' "$head" | cut -c1-12)"
[ -e "$marker" ] && exit 0
touch "$marker" 2>/dev/null || true

cat >&2 <<EOF
Definition-of-done check (~/.claude/shared/git-pr-workflow.md §4): branch
'$branch' has unpushed Claude-authored commits:
$unpushed
If the task is wrapping up: push the branch, make sure a PR exists (draft
while in progress), and report the PR URL. If you truly cannot push, tell the
user exactly where this work lives so it isn't lost. If work is still in
progress, say so briefly and carry on — this check will not re-fire until new
commits land.
EOF
exit 2
