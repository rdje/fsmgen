---
id: memory-pointer-layer-a-content
title: MEMORY.md holds no decision or lane summaries — only current state and the frontier's own context
answers:
  - "what is allowed to live in MEMORY.md?"
  - "why does MEMORY.md keep running out of room?"
  - "can I add a decision summary to MEMORY.md?"
  - "where did the MEMORY.md Durable context block go?"
  - "MEMORY.md is N lines (> cap 120)"
  - "should I raise the MEMORY.md cap when it fills up?"
date: 2026-08-19
status: current
tags: [memory-architecture, live-document-size, containment, decisions, task-trees]
evidence: docs/decisions/0067-layer-a-carries-no-decision-or-lane-summaries.md; MEMORY.md; MEMORY_ARCHITECTURE.md; docs/decisions/INDEX.md; docs/tasks/LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.md
reverify: sed -n '/^## Durable context/,$p' MEMORY.md
---

Layer A carries **current state and the next action only**. It holds no one-line
summaries of decisions and no lane or leaf completion status. Cross-cutting
rationale is `docs/decisions/INDEX.md` (layer C); lane status is the owning tree
under `docs/tasks/` (layer B).

`MEMORY.md` may name the decisions the **current frontier** depends on. That is
bounded by construction because the block is overwritten with the frontier
rather than appended to.

When `MEMORY.md` approaches its cap, **the first question is which content is in
the wrong layer, not what the cap should be.** Decision `0067` was reached after
two slices had already moved limits: 23 of 50 lines were a `Durable context`
block summarising 14 decisions and 10 task leaves, every one verified present in
its own authority. The block grew by one line per decision and per completed
lane, so raising a cap bought time proportional to the raise and changed nothing
about the slope. The `current_state` field had begun the same drift, restating
decisions `0065` and `0066` across 9 lines. Removing both took the file to
**30 lines / 1,690 bytes**.

Every `## Resume` field is now capped at 5 lines by
`MEMORY_POINTER_FIELD_LINE_CAP` in `scripts/check_memory_architecture.sh`, so a
field that starts narrating fails on the write that does it. The drift is an
incentive, not an accident: `COMMIT.md` makes every slice overwrite this file,
so it is the one layer an agent always has open, and one summary line is always
cheaper than opening the right store.

The copy had also drifted: it attributed "PNT is autonomous" to decision `0062`
(push cadence) when the authority is `0003`.

Current bounds are 120 lines and 32,768 bytes — see
[[live-document-target-pair-calibration]] for why those two numbers answer
different questions and neither is derived from the other.
