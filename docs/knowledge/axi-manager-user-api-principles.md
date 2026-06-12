---
id: axi-manager-user-api-principles
title: AXI manager user-facing API principles for future IAL2
answers:
  - "what should AXI manager Easy mode mean?"
  - "is AXI Easy mode a limited mode?"
  - "how should future IAL2 expose AXI manager transactions?"
  - "should Power mode and Raw mode still enforce AXI rules?"
  - "where is the AXI manager user API brainstorm captured?"
date: 2026-06-12
status: current
tags: [axi, ial2, user-api, protocol-intent, manager]
evidence: docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/tasks/AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.md; docs/book/src/14-feature-backlog.md
reverify: rg -n "Easy mode|protocol authority|Supervised Raw|Source-Anchor Boundary" docs/AXI_MANAGER_USER_API_BRAINSTORM.md
---

`docs/AXI_MANAGER_USER_API_BRAINSTORM.md` is the canonical captured
brainstorm for the future AXI manager IAL2 user-facing surface.

Easy mode means conventions over configuration, not reduced AXI capability.
Power mode and supervised Raw mode may expose more control, but the intended
direction is that all normal modes pass through one AXI rule engine that
enforces source-anchored protocol legality. The first ID/order/concurrency
evidence inventory and first rule-matrix design/probe are recorded; any
implementation surface remains future task-tree-owned work.
