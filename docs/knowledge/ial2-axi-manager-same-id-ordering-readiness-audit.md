---
id: ial2-axi-manager-same-id-ordering-readiness-audit
title: Same-ID readiness chose generated auto-ID avoidance assertions
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.34 select?"
  - "what is the first AXI same-ID ordering implementation slice?"
  - "does same-ID ordering need an IAL1 prerequisite?"
  - "what comes after AXI same-ID ordering readiness?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, same-id, ordering, auto-id, assertions, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.34|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.35|avoid_same_id_concurrency|same-ID avoidance|same_id_ordering' docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.34` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.35`: bounded generated auto-ID same-ID
avoidance assertions and machine-readable `same_id_ordering` report metadata.
That implementation has now shipped; see
`docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`.

The readiness audit found no IAL1/IAL0/SystemVerilog prerequisite for the
first same-ID slice. Existing generated auto-ID state, rule guards, assertion
carriers, and SystemVerilog assertion emission can express the pairwise
active selected-ID invariant.

The first implementation should formalize the current conservative behavior:
generated auto-ID families avoid two active transactions sharing one selected
ID. Full per-ID issue-order queues, authored concrete-ID same-ID ordering,
read `RID` response demux, read-data interleaving/reassembly, bursts,
queued/blocking policy, aliases, full-manager behavior, and VHDL remain future
exact-owner work.
