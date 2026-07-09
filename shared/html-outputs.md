# HTML-first outputs

Prefer a rendered HTML page over Markdown for anything substantial I'm meant
to *read*: documents past ~100 lines, anything needing tables, diagrams, or
color, side-by-side comparisons, and reports meant to be shared. Markdown at
that size pushes agents into workarounds — ASCII diagrams, unicode color
approximations — that HTML simply doesn't need, and a link gets read where a
wall of markdown doesn't. (Source: "The unreasonable effectiveness of HTML",
May 2026.)

## Patterns

- **Option comparisons**: one HTML page laying the alternatives out in a grid
  to react to, never sequential markdown sections. Pairs with the divergent-
  prototypes technique in [[reducing-unknowns]].
- **Specs and plans**: a web of small HTML pages across stages (explorations
  → mockups → implementation plan) beats one linear document.
- **Reviews and reports**: annotated diffs, severity color-coding, SVG flow
  diagrams, and a gotchas section.
- **Throwaway tools**: purpose-built single-file HTML editors for the task at
  hand are cheap — always end them with an export action ("copy as JSON",
  "copy as prompt") so the result flows back into the work.
- **Keep the artifacts.** Generated pages double as reference context for
  future sessions and verification.

The token cost over Markdown is real but small next to the difference in
whether the document actually gets read. Plain answers, short notes, and
commit/PR text stay as text — this is for documents, not chat.
