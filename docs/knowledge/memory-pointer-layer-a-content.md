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

Layer A contains only the active frontier, one next action, in-flight/blocker flags
and derived `HEAD`. `0068` removed `current_state`, `push_state` and `Durable context`;
no decision summaries or lane/leaf completion status belong here. Rationale goes
to `docs/decisions/INDEX.md` (C), lane status to `docs/tasks/` (B). Current-frontier
decision references are allowed because the pointer is overwritten, never appended.

At the cap, check routing before raising limits. `0067` followed two limit-moving
slices: `Durable context` occupied 23/50 lines, summarising 14 decisions and 10 leaves,
each verified in its own authority. Growth was one line per decision/completed lane;
raising the cap bought proportional time without changing the slope. `current_state`
also repeated `0065`/`0066` over 9 lines. Removing both left 30 lines/1,690 bytes.

Each Resume field has a 5-line `MEMORY_POINTER_FIELD_LINE_CAP` in
`scripts/check_memory_architecture.sh`; narration fails on the write. The incentive
persists: COMMIT overwrites this always-open file every slice, and one summary line
costs less than opening the right authority. `0068` removed COMMIT's “when recording
completed work”/“the new latest commit” instructions, a stronger recurring force
than restraint rules; its checkpoint was 14 lines/654 bytes.

The copy had wrongly attributed autonomous PNT to `0062` (push cadence), instead
of `0003`. Bounds remain 120 lines/32,768 bytes, answering separate questions with
neither derived from the other: [[live-document-target-pair-calibration]].
