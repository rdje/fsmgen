---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI manager rule-subset selection
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.2|AXI manager rule-subset|post-Valid-Ready|Valid-Ready single/bundle' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready IAL2 surfaces, the active next
feature-completeness slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.2`: select the first AXI manager rule
subset and pre-code contract.

The selector must choose one bounded, source-anchored AXI manager rule family
before any manager behavior is implemented. It must preserve generated IAL1
`.isf` and generated IAL0 `.fsm` review artifacts before SystemVerilog HDL,
record any required IAL1 or IAL0/SV prerequisites, define report/diagnostic
and mdBook sync scope, and keep unsupported rule families explicit residue.

The full AXI manager is not implemented yet. `.pif`/`.ppi`/`.axi` aliases and
extra `.ppif` syntax remain future exact-owner work; they should not jump ahead
of selecting the manager rule subset unless a later selector records a stronger
reason.
