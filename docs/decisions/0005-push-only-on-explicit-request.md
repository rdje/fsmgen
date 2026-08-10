# 0005 — Push only on explicit request

- Date: 2026-06-02
- Type: feedback
- Status: superseded by [0062](0062-push-cadence-is-200-commits.md)

## Context

The agent had been tracking the unpushed-commit count and proposing/​worrying about
pushing at a ~30-commit cadence. The user said: *"Why do you stress out about
pushing? Don't be. We will push at some point, do not worry about this."*

## Decision

- **Push to `origin` only when the user explicitly asks.** There is **no
  commit-count cadence** — the old "~30 commits" trigger is retired.
- Keep accumulating local commits indefinitely; the user initiates pushes on their
  own timing.
- **Do not raise, count down to, or fret about** the push or the ahead-of-origin
  count unprompted.

## Consequences

- Local commit hygiene (every slice committed via `COMMIT.md`, for crash recovery)
  is unchanged and still non-negotiable.
- The only legitimate non-user-initiated push is when a push is genuinely required
  to verify something the user explicitly asked about (e.g. a CI fix).
- Pushing remains an outward-facing action; it is the one continuity step that is
  user-gated rather than autonomous (see `0003`).
