#!/usr/bin/env bash
#
# PreToolUse hook (Bash matcher): deterministic enforcement of the git rules
# in ~/.claude/shared/ that prose alone can't guarantee (per steering.md,
# "must happen deterministically" belongs in a hook):
#
#   1. No commits directly on main/master            (git-pr-workflow.md)
#   2. No force-pushes that touch main/master        (git-pr-workflow.md)
#   3. No commit until the staged diff has passed adversarial review
#      (pre-commit-review.md). Approval is recorded as the SHA-256 of
#      `git diff --staged` in <git-dir>/claude/review-approved, so the
#      approval is tied to the exact diff and self-invalidates the moment
#      the staged content changes (or the commit lands).
#
# Escape hatches — deliberate and visible in the command itself:
#   CLAUDE_ALLOW_MAIN=1  git ...   intentional commit/force-push on main
#   CLAUDE_SKIP_REVIEW=1 git ...   trivial non-code commit (docs typo, etc.)
#
# Exit 0 allows the tool call; exit 2 blocks it and feeds stderr back to
# Claude. Every unexpected condition fails OPEN (exit 0) so a broken hook,
# missing dependency, or exotic command can never brick commits.

set -u

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat) || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# Matches "git <flags...> <subcommand>" anywhere in the command line, with
# only option-ish tokens (-C <dir>, --git-dir=..., -c x=y, ...) between the
# word "git" and the subcommand — so "git log | grep commit" does NOT match.
GIT_RE='(^|[^[:alnum:]._-])git[[:space:]]+((-C|-c|--git-dir=?|--work-tree=?)[[:space:]]*[^[:space:]]+[[:space:]]+|-[^[:space:]]+[[:space:]]+)*'
is_git() { printf '%s\n' "$cmd" | grep -Eq "${GIT_RE}$1([[:space:]]|\$)"; }

is_git commit || is_git push || exit 0

# An escape hatch counts only as a real env-var assignment prefixing a git
# invocation (start of a command position, optionally after `env` or other
# assignments) — NOT as a substring anywhere, or a commit message that merely
# *mentions* the token would silently defeat the gate.
# Known limitation (accepted, fails open): the check is line-based, so a
# multi-line commit-message BODY containing a line that literally starts with
# `CLAUDE_SKIP_REVIEW=1 ... git` (e.g. docs quoting this very hook) matches.
has_hatch() {
  printf '%s\n' "$cmd" | grep -Eq \
    "(^|[;&|][[:space:]]*)(env[[:space:]]+)?([[:alnum:]_]+=[^[:space:]]*[[:space:]]+)*$1[[:space:]]+([[:alnum:]_]+=[^[:space:]]*[[:space:]]+)*(command[[:space:]]+)?git([[:space:]]|\$)"
}

# Best-effort repo dir: `git -C <dir>` wins; else the LAST `cd <dir>` at any
# command position (own line, or after && ; |) — multi-line commands are the
# normal shape here; else the session cwd.
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
cdir=$(printf '%s\n' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+"?([^"[:space:]]+)"?.*/\1/p' | head -n1)
cddir=$(printf '%s\n' "$cmd" \
  | grep -oE '(^|[;&|][[:space:]]*)cd[[:space:]]+("[^"]+"|[^"[:space:];&|]+)' \
  | tail -n1 \
  | sed -E 's/^(.*[;&|][[:space:]]*)?cd[[:space:]]+//; s/^"//; s/"$//')
repo="${cdir:-${cddir:-$cwd}}"
case "$repo" in
  "~"*) repo="${HOME}${repo#\~}" ;;
  /*) : ;;
  *) [ -n "$repo" ] && repo="${cwd%/}/$repo" ;;
esac
[ -n "$repo" ] && [ -d "$repo" ] || repo="$cwd"
[ -n "$repo" ] && [ -d "$repo" ] || exit 0

branch=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || true)
on_trunk=false
[ "$branch" = "main" ] || [ "$branch" = "master" ] && on_trunk=true

sha_stdin() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }

# ---------------------------------------------------------------- commit ---
if is_git commit; then
  if $on_trunk && ! has_hatch 'CLAUDE_ALLOW_MAIN=1'; then
    cat >&2 <<EOF
BLOCKED by ~/.claude/hooks/git-safety.sh: you are committing directly on '$branch'.
Per ~/.claude/shared/git-pr-workflow.md, work happens on a branch off origin/main:
  git checkout -b <topic-branch> origin/$branch
then commit there and open a draft PR. If committing on '$branch' is genuinely
intentional, prefix the command: CLAUDE_ALLOW_MAIN=1 git commit ...
EOF
    exit 2
  fi

  if ! has_hatch 'CLAUDE_SKIP_REVIEW=1'; then
    gitdir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null || true)
    if [ -n "$gitdir" ]; then
      staged_hash=$(git -C "$repo" diff --staged 2>/dev/null | sha_stdin | awk '{print $1}')
      approved_hash=$(cat "$gitdir/claude/review-approved" 2>/dev/null || true)
      if [ -z "$approved_hash" ] || [ "$staged_hash" != "$approved_hash" ]; then
        cat >&2 <<'EOF'
BLOCKED by ~/.claude/hooks/git-safety.sh: the staged diff has not passed
adversarial pre-commit review (~/.claude/shared/pre-commit-review.md), or it
changed after approval. To proceed:
  1. Stage the COMPLETE change (this gate hashes `git diff --staged`; don't
     rely on `commit -a`).
  2. Have a fresh reviewer subagent review the staged diff until it APPROVEs.
  3. Record the approval:
       gitdir=$(git rev-parse --absolute-git-dir) && mkdir -p "$gitdir/claude" && \
       git diff --staged | (shasum -a 256 2>/dev/null || sha256sum) | awk '{print $1}' \
         > "$gitdir/claude/review-approved"
  4. Re-run the commit without touching the staged diff.
Trivial non-code commit (docs typo, .gitignore tweak)? Bypass deliberately:
  CLAUDE_SKIP_REVIEW=1 git commit ...
EOF
        exit 2
      fi
    fi
  fi
fi

# ------------------------------------------------------------------ push ---
if is_git push; then
  # Force flags: long forms, plus any bundled short-flag cluster containing
  # `f` (git accepts `git push -uf ...` as a forced update), plus `+refspec`.
  if printf '%s\n' "$cmd" | grep -Eq '(^|[[:space:]])--force(-with-lease[^[:space:]]*|-if-includes)?([[:space:]]|$)' \
     || printf '%s\n' "$cmd" | grep -Eq '(^|[[:space:]])-[[:alnum:]]*f[[:alnum:]]*([[:space:]]|$)' \
     || printf '%s\n' "$cmd" | grep -Eq '[[:space:]]\+[^[:space:]]+'; then
    if ! has_hatch 'CLAUDE_ALLOW_MAIN=1'; then
      if printf '%s\n' "$cmd" | grep -Eq '(^|[[:space:]]|:|\+)(main|master)([[:space:]]|$)' \
         || $on_trunk; then
        cat >&2 <<EOF
BLOCKED by ~/.claude/hooks/git-safety.sh: force-push involving main/master.
Per ~/.claude/shared/git-pr-workflow.md, never rewrite history on the default
branch. Force-pushing a rebased FEATURE branch is fine — name it explicitly
(git push --force-with-lease origin <topic-branch>). If this really must touch
main, prefix the command: CLAUDE_ALLOW_MAIN=1 git push ...
EOF
        exit 2
      fi
    fi
  fi
fi

exit 0
