# claude-config

My portable [Claude Code](https://claude.com/claude-code) user configuration —
the cross-project conventions that orient every agent I run, plus a few settings.
Kept in git so I can sync it between machines and share it with others, instead
of maintaining these patterns per-project.

## What's here

| Path | What it is |
|---|---|
| `CLAUDE.md` | Thin entry point loaded for every project. `@`-imports the guides below. |
| `shared/*.md` | One convention per file, cross-linked with `[[name]]`: git/PR workflow, adversarial pre-commit review, model selection, the advisor, orchestration, critical feedback. |
| `settings.json` | Personal Claude Code defaults (model, statusline, theme, enabled plugins). Adjust to taste on a shared machine. |
| `statusline-command.sh` | Custom status line script referenced by `settings.json`. |
| `install.sh` | Symlinks the above into `~/.claude/`. |

The imports in `CLAUDE.md` use home-relative paths (`@~/.claude/shared/...`), so
they resolve for any user on any machine with no rewriting.

## What's deliberately **not** here

`~/.claude/` also holds secrets, history, and runtime state that must never be
committed — this repo excludes all of it (and `.gitignore` blocks it defensively):

- `.credentials.json` — OAuth token
- `history.jsonl`, `projects/` — prompt history and full conversation transcripts
- `settings.local.json` — per-machine permission grants
- caches / daemon / sessions / backups and other runtime dirs
- auto-memory under `projects/.../memory/` — personal, and its path encodes the
  home dir, so it's neither shareable nor portable

## Install

```bash
git clone <this-repo> ~/claude-config
cd ~/claude-config
./install.sh
```

`install.sh` symlinks each tracked item into `~/.claude/`. It's safe to re-run:
already-correct links are skipped, and anything real it would replace is moved
aside to a timestamped `.backup` first — nothing is deleted. Set
`CLAUDE_CONFIG_DIR` to target a non-default location.

Because the files are symlinked, editing them in `~/.claude/` edits the repo
directly — commit and push to propagate to your other machines.

## Extending

Add a new global convention as its own `shared/<name>.md` file and add one
`@~/.claude/shared/<name>.md` import line to `CLAUDE.md` — keep `CLAUDE.md` thin.
