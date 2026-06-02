# 0003 — Autonomous PNT; do not pause mid-flow

- Date: 2026-06-02 (migrated from harness-home memory + reinforced this session)
- Type: feedback
- Status: accepted

## Context

The user repeatedly expressed frustration when the agent stopped mid-task to
summarize and await direction ("Why are you pausing? I do not understand" — twice).
They want continuous delivery and autonomous progress through the backlog.

## Decision

- **PNT (pick-next-task) through frontier/backlog items autonomously, any order.**
  Do not ask "which item is next" — choose and proceed.
- **Do not pause mid-flow** to summarize-and-await on a single well-scoped task.
  Keep delivering: implement → focused test → simulate → docs → gates → commit.
- A brief checkpoint is warranted only at a *genuine boundary* — the end of a large
  coherent body of work where the next step is big/ambiguous/gated — not as
  reflexive mid-task dithering.

## Consequences

- Commit low-risk ISF-layer slices on focused-test + simulation + `--verify-hdl`
  evidence, running the full suite as background confirmation rather than blocking.
- Minimize summary-and-await turns. When unsure between equally-valid clean
  next steps, pick the highest-value one and go.
- Outward-facing/hard-to-reverse actions (notably `git push`, per `0005`) still
  require explicit user direction — that is not "pausing," it is respecting a gate.
