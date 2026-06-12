---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI manager capacity/status readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.3|capacity/status|outstanding-capacity|acceptance/status|readiness audit' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready IAL2 surfaces,
`IAL2-FEATURE-COMPLETENESS-FRONTIER.2` selected the first AXI manager rule
subset: outstanding transaction capacity plus acceptance/status feedback.

The active next feature-completeness slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.3`: audit implementation readiness for
that selected capacity/status subset. The audit must decide whether existing
`.ppif`, IAL2 report, IAL1, IAL0, and SystemVerilog surfaces can support the
subset or whether explicit prerequisite leaves are needed before behavior
changes.

The full AXI manager is not implemented yet. `.pif`/`.ppi`/`.axi` aliases and
extra `.ppif` syntax remain future exact-owner work; they should not jump ahead
of the capacity/status readiness and implementation path unless a later
selector records a stronger reason.
