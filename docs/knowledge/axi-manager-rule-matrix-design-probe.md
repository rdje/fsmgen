---
id: axi-manager-rule-matrix-design-probe
title: AXI manager rule-matrix design probe
answers:
  - "where is the AXI manager rule matrix?"
  - "what should the AXI manager rule engine enforce?"
  - "how should AXI manager Easy mode handle concurrency?"
  - "what AXI manager work remains residue?"
  - "is the AXI manager rule matrix implemented?"
date: 2026-06-12
status: current
tags: [axi, ial2, manager, rule-matrix, design-probe]
evidence: docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_VALID_READY_INTENT_PROBE.md; docs/tasks/AXI-MANAGER-RULE-MATRIX-DESIGN-PROBE.md
reverify: rg -n "Rule Matrix|First-Implementation Gate|Current Conclusion" docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md
---

`docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md` is the canonical first rule
responsibility matrix for a future IAL2 AXI manager.

The rule matrix is design/probe evidence only. It says a future manager should
own valid/ready behavior, outstanding capacity, ID allocation/validation,
same-ID ordering, response matching, read-data interleaving policy,
write-data sequencing, unique-in-flight constraints, capability assumptions,
and residue reporting. It does not implement IAL2 syntax, lowering, `.isf`,
`.fsm`, HDL, assertions, queue defaults, or ID allocation algorithms.
