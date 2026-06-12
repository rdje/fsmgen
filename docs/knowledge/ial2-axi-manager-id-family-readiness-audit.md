---
id: ial2-axi-manager-id-family-readiness-audit
title: AXI manager ID-family readiness selects additive capacity/status extension
answers:
  - "how should AXI ID-family static validation be implemented?"
  - "does AXI ID-family support need a new manager object first?"
  - "does AXI ID-family support need IAL1 or HDL changes first?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.9 implement?"
  - "should id_families change generated .isf or HDL?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id-family, readiness, ppif]
evidence: docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'id_families|id-families|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.9|generated \\.isf|generated \\.fsm|unchanged|additive' docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

The AXI manager ID-family/static-validation readiness audit selected an
additive optional `id_families` extension to the existing
`manager-capacity-status` object as the first implementation boundary. A new
full manager object is deferred until transaction verbs, ID allocation,
ordering, and response matching are selected.

No IAL1, IAL0, or SystemVerilog prerequisite is required first. The first
implementation should parse, validate, and report static ID-family metadata
without changing generated `.isf`, generated `.fsm`, or HDL behavior.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.9` implemented the selected boundary: it
adds public `(id-families ...)` syntax, a separate sample, support-accounting
entry, additive report `id_families`, fail-closed diagnostics, mdBook/Knowledge
Map sync, and focused tests. The active frontier after that slice is `.10`, a
selector for the next IAL2 feature-completeness slice.
