---
id: ial2-axi-manager-auto-id-lifecycle-selection
title: AXI manager auto-ID lifecycle readiness is selected
answers:
  - "what comes after AXI concrete ID assertions?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.20?"
  - "is AXI auto-ID allocation implemented now?"
  - "what must happen before AXI auto-ID allocation?"
  - "why is request-ID drive readiness next?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, auto-id, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'auto-ID lifecycle|request-ID drive|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.20|ID busy/free|completion release|auto-ID allocation' docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After concrete transaction ID assertions shipped, the next selected IAL2 AXI
manager subset is auto-ID lifecycle/readiness.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.19` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.20` as the readiness-audit owner.

The audit must decide whether a first auto-ID lifecycle slice can extend the
existing `manager-capacity-status` object and current IAL1/IAL0/SystemVerilog
substrate, or whether a narrower request-ID drive, storage, or expression
prerequisite must ship first.

Auto-ID allocation is not implemented now. Request-ID drive direction, ID
busy/free state, completion release, no-ID-available diagnostics, report
metadata, and validation gates must be selected before any allocation behavior
change.
