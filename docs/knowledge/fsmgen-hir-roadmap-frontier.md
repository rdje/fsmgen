---
id: fsmgen-hir-roadmap-frontier
title: FSMGEN HIR roadmap and selected SourceHIR boundary
answers:
  - "what owns the FSMGEN HIR roadmap phase?"
  - "should high-level frontends lower directly to IAL1 or IAL2?"
  - "what is the proposed FSMGEN HIR architecture?"
  - "how does FSMGEN HIR relate to IAL1 and IAL2?"
  - "is the source-facing FSMGEN HIR architecture audit active now?"
  - "what follows the SourceHIR architecture selection?"
date: 2026-06-28
status: current
tags: [architecture, hir, ial1, ial2, frontend, task-tree, roadmap]
evidence: docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md; docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md; docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md; docs/decisions/0028-source-facing-hir-is-a-distinct-private-pre-ial-layer.md; docs/decisions/0029-source-hir-remains-private-through-a-second-lowering-route.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md; docs/IR_POLICY.md; docs/tasks/FSMGEN-IR-AUDIT.md; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md
reverify: rg -n 'FSMGEN-HIR-ROADMAP-FRONTIER|FSM::IR::SourceHIR|valid_ready_handshake\.ppif|private|IAL2 -> IAL1 -> IAL0' docs/tasks/FSMGEN-HIR-ROADMAP-FRONTIER.md docs/FSMGEN_SOURCE_HIR_ARCHITECTURE_SELECTION.md docs/FSMGEN_SOURCE_HIR_POST_PROTOTYPE_AUDIT.md docs/TASK_TREE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`FSMGEN-HIR-ROADMAP-FRONTIER` owns the source-facing FSMGEN HIR roadmap phase.
Leaf `.2` selects a distinct private `FSM::IR::SourceHIR` rather than extending
the existing post-parse `IntentHIR`.

The recorded architecture direction is:

`high-level frontend -> FSMGEN HIR -> validation/canonicalization -> IAL2 or IAL1 -> existing lowering`

The HIR does not replace IAL1 or IAL2. It sits above them as a stable semantic
input layer: HIR should lower to IAL2 when the source expresses
protocol/platform intent and to IAL1 when the source is already concrete
FSM/control logic.

The first producer is a repository-internal constrained Perl builder. It
validates one protocol-neutral valid-ready object, renders canonical `.ppif`,
and uses the existing parser plus `IAL2 -> IAL1 -> IAL0` chain. The first
golden is `ppif/valid_ready_handshake.ppif`, reproduced byte-for-byte.

The prototype remains private and adds no CLI, public host-language API,
normalized-report key, or support-accounting promise. Leaf `.3` freezes the
exact version-1 contract in `docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md` without
implementation. Leaf `.4` now implements and proves the private
three-package/t1547 valid-ready path. Audit `.5` keeps that healthy path
private because one test producer, one schema, and only the IAL2 route are not
enough to freeze a public contract. Clean audit commit `5d018edbd` activates
`.6` continuity-only to select the exact private concrete-control-to-IAL1
boundary; `.7` implements it and `.8` re-audits promotion.
