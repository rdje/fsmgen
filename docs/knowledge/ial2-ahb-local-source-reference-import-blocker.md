---
id: ial2-ahb-local-source-reference-import-blocker
title: AHB subordinate source work was blocked on a local AHB/AHB-Lite reference artifact before .706
answers:
  - "what blocked IAL2-FEATURE-COMPLETENESS-FRONTIER.705 before .706?"
  - "why was AHB source-fact extraction blocked at the end of .705?"
date: 2026-06-29
status: historical
tags: [ial2, ahb, subordinate, source-reference, blocker, vendor, task-tree]
evidence: docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md; docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.705|historical blocker|resolved by|IAL2-FEATURE-COMPLETENESS-FRONTIER\.706' docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT_BLOCKER.md docs/IAL2_AHB_LOCAL_SOURCE_REFERENCE_IMPORT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.705` ended blocked. At that time, a
repo-local search found no acceptable AHB/AHB-Lite source reference artifact
under tracked `docs/vendor/` or the local `.cache/local-references/` mirror.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.706` later resolved the local source
availability blocker by importing the user-approved Arm AMBA AHB Protocol
Specification PDF under `docs/vendor/arm/amba/ahb/`.

This historical blocker still explains why `.705` could not extract source
facts or select a lower-layer direct `.fsm` subordinate seed contract. Current
source availability is recorded in
`docs/knowledge/ial2-ahb-local-source-reference-import.md`.

No source reference, source facts, seed, parser/generator behavior,
support-accounting, manifest, test behavior, generated artifact, HDL/runtime
behavior, direct backend, verification-output, backend-language variant, AXI,
APB, or VHDL behavior changed in `.705`.
