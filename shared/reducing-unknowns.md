# Reducing unknowns — surface the gaps before they bite

On ambiguous or unfamiliar work, the bottleneck usually isn't model capability
— it's the gap between what the task statement says and what actually matters:
the constraints I'd never think to write down, and the ones neither of us
knows exist yet. Spend effort shrinking that gap at the edges of the task,
not just executing the middle.

## Before building

- **Blind spot pass** — when I'm on unfamiliar ground, say so ("I know
  nothing about the auth modules here") and ask for the unknown-unknowns to
  be surfaced and explained before any plan is written.
- **Interview me** — but only on questions whose answers would change the
  architecture. Exhaustive Q&A is noise; a data-model question is signal.
- **Multiple divergent prototypes** — several wildly different directions in
  one side-by-side comparison surface the criteria I can't articulate but
  will recognize on sight (see [[html-outputs]] for the format).
- **References beat descriptions** — an existing implementation (even in
  another language) is richer signal than screenshots or prose specs.
- **Plans should dwell on the uncertain parts** — data-model changes, new
  type interfaces, anything user-facing — not restate the obvious ones.

## During

- **Deliver at the scope intended.** Make routine judgment calls yourself and
  check in only when different readings would lead to materially different
  work. If the ask seems mistaken or a better approach exists, say so in a
  sentence and keep going with the task as asked — don't quietly narrow,
  widen, or transform it.
- **Keep a deviations log.** On an edge case that forces a departure from the
  plan, pick the conservative option, record it under a "Deviations" heading
  in a scratch notes file, and keep going — don't stop to ask on every edge
  case, and don't silently absorb the change either.

## After

- **Explainer** — a demo-first document combining the prototype, the spec,
  and the implementation notes, for anyone who needs to buy in.
- **Quiz me** — a report on what changed plus a short quiz I must pass. If I
  can't pass it, I don't understand what shipped, and that's worth knowing
  before it's in main.

Calibrate prompt specificity both ways: too specific and instructions get
followed even when a pivot is right; too vague and industry-default
assumptions fill the gaps whether or not they fit. The [[advisor]] covers the
related mid-task lever — decision quality at commitment points.
