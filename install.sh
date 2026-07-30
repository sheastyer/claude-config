#!/usr/bin/env bash
#
# Symlink this repo's portable Claude Code config into ~/.claude/.
#
# Safe to re-run: already-correct links are left alone, and anything real
# that would be overwritten is moved aside to a timestamped .backup first.
# Nothing is ever deleted.

set -euo pipefail

# Repo root = the directory this script lives in (works wherever it's cloned).
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Files/dirs to link, relative to both REPO and CLAUDE_DIR.
ITEMS=(
  "CLAUDE.md"
  "shared"
  "hooks"
  "settings.json"
  "statusline-command.sh"
  # Skills are linked per-skill (not the whole skills/ dir) so repo skills can
  # coexist with machine-local ones already in ~/.claude/skills/.
  "skills/claude-code-blog-sync"
  "skills/steering"
  "skills/loop-design"
)

# Inode identity, not string equality: catches trailing-slash / relative / alias
# spellings of the same directory that a raw "=" comparison would miss.
if [ -e "$CLAUDE_DIR" ] && [ "$REPO" -ef "$CLAUDE_DIR" ]; then
  echo "error: repo is \$CLAUDE_DIR itself ($CLAUDE_DIR); refusing to self-link." >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

link() {
  local rel="$1"
  local src="$REPO/$rel"
  local dest="$CLAUDE_DIR/$rel"

  if [ ! -e "$src" ]; then
    echo "skip: $rel (not present in repo)"
    return
  fi

  # Refuse when src and dest are literally the same real file (self-link): moving
  # it aside and re-linking would leave a dangling symlink to a vanished source.
  if [ ! -L "$dest" ] && [ -e "$dest" ] && [ "$src" -ef "$dest" ]; then
    echo "skip: $rel (source and destination are the same file)"
    return
  fi

  # Already resolves to our source (inode identity, so equivalent path spellings
  # still count)? Nothing to do — keeps re-runs idempotent, no backup churn.
  if [ -L "$dest" ] && [ "$dest" -ef "$src" ]; then
    echo "ok:   $rel (already linked)"
    return
  fi

  # Move any existing real file/dir/other-symlink aside — never overwrite.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    # Second-resolution timestamps can collide; find a free name so a repeat
    # backup can never clobber (and destroy) a previous one.
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      local n=1
      while [ -e "${backup}.${n}" ] || [ -L "${backup}.${n}" ]; do
        n=$((n + 1))
      done
      backup="${backup}.${n}"
    fi
    mv "$dest" "$backup"
    echo "back: $rel -> $(basename "$backup")"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "link: $rel -> $src"
}

for item in "${ITEMS[@]}"; do
  link "$item"
done

echo
echo "Done. Linked into $CLAUDE_DIR"
