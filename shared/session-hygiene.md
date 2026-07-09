# Session hygiene — context and cache are the workspace

Model quality degrades as context grows (attention spreads across more
tokens), and the prompt cache that makes long sessions affordable only
survives when the prefix stays stable. Treat both as things to manage, not
side effects. (Sources: "Session management and 1M context", Apr 2026;
"Prompt caching is everything", Apr 2026.)

## Session boundaries

- **New task → new session.** `/clear` gives zero rot and full control over
  what carries forward; continue in-session only when everything in the
  window is still load-bearing.
- **Steer `/compact` instead of trusting autocompact**, especially after
  long or directionless stretches: `/compact focus on the auth refactor,
  drop the test debugging`.
- **Prefer `/rewind` (double-Esc) over typed corrections** when a turn goes
  wrong — rewind to just after the file reads rather than arguing with a
  bad attempt mid-thread.
- **The subagent test:** "Will I need this tool output again, or just the
  conclusion?" Just the conclusion → do it in a subagent and keep the main
  thread clean (see [[orchestration]]).

## Cache-preserving habits

Caching is prefix-matching: static content first, dynamic content last, and
anything that mutates the prefix rebuilds the whole cache.

- **Don't switch models mid-session** — caches are model-specific, so a
  mid-conversation swap silently re-reads the entire context at full price.
  Need a different model? Start a fresh session or spawn a subagent on it.
- **Keep the tool set stable** — adding or removing tools (or MCP servers)
  mid-session invalidates the cached prefix for the rest of the
  conversation.
- **Keep volatile data out of CLAUDE.md, skills, and system prompts** — no
  timestamps, session IDs, or frequently-edited state in always-loaded
  files; pass dynamic information in messages, where it doesn't poison the
  prefix.
