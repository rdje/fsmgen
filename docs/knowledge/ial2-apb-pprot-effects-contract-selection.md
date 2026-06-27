---
id: ial2-apb-pprot-effects-contract-selection
title: APB PPROT effects contract selects register-local privileged policy
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.596?"
  - "what APB PPROT policy syntax was selected?"
  - "what comes after APB PPROT effects readiness?"
  - "how do denied APB PPROT policy accesses behave?"
  - "what owns APB PPROT protection implementation?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, contract, task-tree]
evidence: docs/IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md; docs/IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.596|IAL2-FEATURE-COMPLETENESS-FRONTIER\.597|access-policy|privileged|apb_additional_protection_policies_deferred|public APB PPROT access-control effects contract' docs/IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.596` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.597`, direct bounded implementation of
the first APB `PPROT` access-control effects contract, without behavior
changes.

The selected public syntax is a register-local `(access-policy ...)` clause on
sideband-aware 32-bit APB completer storage registers. The first predicate is
FSMGen-local `(privileged VALUE)`, defined as sampled `PPROT[0] == VALUE`.

Denied mapped reads and writes complete at the normal APB response point with
`PREADY=1` and `PSLVERR=1`. Denied reads drive `PRDATA=0`; denied writes are
side-effect-free, including when `PSTRB=0`. Fixed and multi-peripheral
composition only propagate `PPROT` and mux the selected response in this first
slice; the selected completer owns register-local enforcement.
