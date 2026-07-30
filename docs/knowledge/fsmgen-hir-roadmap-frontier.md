---
id: fsmgen-hir-roadmap-frontier
title: FSMGEN HIR roadmap phase captured
answers:
  - "what owns the FSMGEN HIR roadmap phase?"
  - "should high-level frontends lower directly to IAL1 or IAL2?"
  - "what is the proposed FSMGEN HIR architecture?"
  - "how does FSMGEN HIR relate to IAL1 and IAL2?"
  - "is the source-facing FSMGEN HIR architecture audit active now?"
date: 2026-06-28
status: current
tags: [architecture, hir, ial1, ial2, frontend, task-tree, roadmap]
evidence: docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md; docs/IR_POLICY.md; docs/tasks/FSMGEN-IR-AUDIT.md; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md
reverify: rg -n 'FSMGEN-HIR-ROADMAP-FRONTIER|source-facing HIR|high-level frontend -> FSMGEN HIR|HIR sits above them|not replace IAL1 or IAL2' docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`FSMGEN-HIR-ROADMAP-FRONTIER` owns the source-facing FSMGEN HIR roadmap phase.
Clean parent selector commit `b4e66c067` activates architecture-selection leaf
`.2` continuity-only.

The recorded architecture direction is:

`high-level frontend -> FSMGEN HIR -> validation/canonicalization -> IAL2 or IAL1 -> existing lowering`

The HIR does not replace IAL1 or IAL2. It sits above them as a stable semantic
input layer: HIR should lower to IAL2 when the source expresses
protocol/platform intent and to IAL1 when the source is already concrete
FSM/control logic.

Active `.2` is a design selection/audit leaf. It must satisfy
`docs/IR_POLICY.md` before parser, compiler, source, generated-artifact, config,
or behavior changes begin. The activation itself selects no architecture.
