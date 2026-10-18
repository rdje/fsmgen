---
id: memory-pointer-layer-a-content
title: MEMORY.md holds frontier state, never decision or lane summaries
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

Layer A: active frontier, one next action, in-flight/blocker flags, derived `HEAD`.
`0068` removed `current_state`, `push_state` and `Durable context`. Decisions go to
`docs/decisions/INDEX.md` (C), lane/leaf completions to `docs/tasks/` (B).
Frontier decision references are allowed because the pointer is overwritten,
never appended; summaries are not.

Check routing before raising caps. `0067` followed two limit-moving slices:
`Durable context` used 23/50 lines for 14 decisions and 10 leaves, each verified
in its authority. Growth was one line per decision/completed lane; caps bought
proportional time, not a different slope. `current_state` repeated `0065`/`0066`
over 9 lines. Removing both left 30 lines/1,690 bytes.

Each Resume field has a 5-line `MEMORY_POINTER_FIELD_LINE_CAP` in
`scripts/check_memory_architecture.sh`; narration fails on write. COMMIT
overwrites this always-open file every slice; a summary line costs less than
opening its authority. `0068` removed the stronger recurring COMMIT prompts
“when recording completed work”/“the new latest commit”, beyond restraint rules;
its checkpoint was 14 lines/654 bytes.

PNT is `0003`, not push-cadence `0062` (the copy's former error). Bounds remain
120 lines/32,768 bytes: separate questions, neither derived from the other
([[live-document-target-pair-calibration]]).
