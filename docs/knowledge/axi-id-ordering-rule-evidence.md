---
id: axi-id-ordering-rule-evidence
title: AXI ID/order/concurrency source-anchor evidence inventory
answers:
  - "where is the AXI ID ordering source-anchor evidence?"
  - "what AXI spec anchors define ID ordering and concurrency?"
  - "is AXI ID ordering implemented as IAL2?"
  - "what rules should a future AXI manager rule engine own?"
  - "does AXI Easy mode need to support multiple pending transactions?"
date: 2026-06-12
status: current
tags: [axi, ial2, id-ordering, concurrency, manager, source-anchors]
evidence: docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf; docs/tasks/AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.md
reverify: rg -n "A5\\.1|A5\\.3|A5\\.5|A5\\.6|B3 Summary" docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md
---

`docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md` is the canonical repo-local
evidence inventory for AXI transaction IDs, ordering, outstanding
concurrency, response matching, and read/write data interleaving.

The fact established by the card is intentionally narrow: AXI ID/order rules
are source evidence for a future IAL2 AXI manager rule engine, not a shipped
IAL2 implementation. A future Easy-mode AXI manager should be allowed to use
multiple pending transactions, but only through a source-anchored rule engine
that owns ID allocation/validation, per-ID outstanding tracking, same-ID
ordering, response matching, interleaving policy, capacity feedback, and
explicit residue. The first rule responsibility matrix is recorded in
`docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`; implementation remains future
task-tree-owned work.
