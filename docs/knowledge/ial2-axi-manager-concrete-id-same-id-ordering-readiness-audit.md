---
id: ial2-axi-manager-concrete-id-same-id-ordering-readiness-audit
title: Concrete-ID same-ID readiness selects a fail-closed static diagnostic
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.87?"
  - "what did the concrete-ID same-ID ordering readiness audit select?"
  - "what comes after AXI concrete-ID same-ID ordering readiness?"
  - "should concrete-ID same-ID ordering implement per-ID queues next?"
  - "does FSMGen currently allow two concrete transactions with the same AXI ID?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, diagnostic, task-tree]
evidence: docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.87|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.88|CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT|fail-closed static validation|same concrete ID' docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.87` audited AXI concrete-ID same-ID
ordering readiness after bounded burst residue alignment.

The audit found that generated auto-ID same-ID ordering is already handled by
avoidance, but authored concrete-ID transactions can still share the same ID
when their events are unique. The current concrete-ID assertion slice only
checks request/response ID equality; it does not preserve same-ID response
issue order.

The selected next owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`,
fail-closed static validation for multiple concrete-ID transactions in the
same read or write response family that use the same concrete ID value. It
should not implement per-ID issue-order queues first.
