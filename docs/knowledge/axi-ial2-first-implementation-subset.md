---
id: axi-ial2-first-implementation-subset
title: AXI-derived IAL2 first implementation subset selection
answers:
  - "what is the first AXI-derived IAL2 implementation subset?"
  - "should the first AXI IAL2 implementation be the full manager?"
  - "what must the first AXI IAL2 implementation lower to?"
  - "what remains out of scope for the first AXI IAL2 implementation?"
  - "where is the first AXI IAL2 implementation selection documented?"
date: 2026-06-12
status: current
tags: [axi, ial2, implementation-selection, valid-ready, lowering]
evidence: docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md; docs/AXI_VALID_READY_INTENT_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/tasks/AXI-IAL2-FIRST-IMPLEMENTATION-SUBSET-SELECTION.md
reverify: rg -n "Selected First Subset|Required IAL1 Artifact Shape|Required IAL0 Artifact Shape|Explicit Residue" docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md
---

`docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md` selects the first
safe AXI-derived IAL2 implementation subset: a source-anchored AXI
Valid-Ready channel contract/monitor.

The first implementation should not be the full AXI manager. It must prove the
`IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL` chain, generate reviewable IAL1 and
IAL0 artifacts, emit source-anchor/residue reports, and leave IDs,
outstanding windows, response matching, bursts, interleaving, and full
Easy/Power/supervised Raw manager behavior for later exact-owner work.
