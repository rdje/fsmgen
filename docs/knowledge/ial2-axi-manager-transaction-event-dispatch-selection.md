---
id: ial2-axi-manager-transaction-event-dispatch-selection
title: AXI manager transaction event dispatch selected before ID allocation
answers:
  - "what comes after AXI transaction-envelope metadata?"
  - "why not implement AXI ID allocation immediately?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.14?"
  - "what prerequisite is needed before AXI response matching?"
  - "how will AXI transactions get per-transaction event provenance?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, transaction-envelope, event-dispatch, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'transaction event dispatch|direction fan-in|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.14|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.15|per-transaction request|per-transaction event provenance|ID allocation|transaction_event_dispatch' docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped structural `(transactions ...)` metadata slice, the next
selected IAL2 prerequisite is AXI manager transaction event dispatch and
direction fan-in.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` readiness-audited whether distinct
per-transaction request/completion events can fan into the existing read/write
capacity/status rule matrices through the current IAL1/IAL0/SystemVerilog
path. It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.15` as the additive
implementation owner.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.15` shipped that prerequisite with
generated transaction-event inputs, OR fan-in guards, additive
`transaction_event_dispatch` report metadata, and bounded IAL1 OR/negated-OR
guard conflict proof support.

ID allocation, same-ID ordering, response matching, read-data interleaving,
and transaction-specific completion reporting remain deferred because they
need per-transaction event provenance first.
