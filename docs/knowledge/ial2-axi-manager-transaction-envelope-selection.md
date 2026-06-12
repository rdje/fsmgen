---
id: ial2-axi-manager-transaction-envelope-selection
title: AXI manager transaction-envelope/static-validation subset selected
answers:
  - "what comes after AXI manager ID-family metadata?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.10?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.11?"
  - "why is a transaction envelope needed before ID allocation?"
  - "should AXI transaction intent be machine readable?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, transaction-envelope, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'transaction-envelope|transaction envelope|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.10|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.11|machine-readable|AST/structural|requested-ID' docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.10` selected the next AXI manager subset:
a machine-readable AST/structural logical read/write transaction envelope and
static validation contract.

The envelope is needed before ID allocation, ordering queues, or response
matching because those later behaviors need a stable place to attach
transaction names, read/write kind, user-visible tags, request/completion
event bindings, optional requested-ID policy or value, source anchors, and
report metadata.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.11` is the active next leaf. It must audit
whether the first implementation extends `manager-capacity-status`, introduces
a broader manager object, or requires an IAL1/IAL0/SystemVerilog prerequisite
before behavior changes.
