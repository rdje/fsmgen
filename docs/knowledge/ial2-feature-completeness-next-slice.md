---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is transaction-event dispatch readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.14|transaction event dispatch|direction fan-in|per-transaction event provenance|capacity/status|transactions' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
and transaction-envelope metadata IAL2 surfaces, the next active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.14`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` is a readiness audit for AXI manager
transaction event dispatch and direction fan-in. It must decide whether
distinct per-transaction request/completion events can feed the existing
read/write capacity/status rules through the current IAL1/IAL0/SV path, or
whether another prerequisite is required first.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.12` shipped the bounded AXI manager
machine-readable AST/structural logical read/write transaction-envelope
metadata slice.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.13` selected the event-dispatch
prerequisite because dynamic ID allocation and response matching need
per-transaction event provenance first.

The full AXI manager is not implemented yet. ID allocation, ordering, response
matching, bursts, queued/blocking policy, `.pif`/`.ppi`/`.axi` aliases, and
VHDL remain future exact-owner work; they should not jump ahead of the
transaction-event-dispatch readiness audit unless that audit records a
stronger reason.
