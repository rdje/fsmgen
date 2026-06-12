---
id: ial2-axi-manager-transaction-envelope-first-slice
title: AXI manager transaction-envelope metadata first slice is shipped
answers:
  - "is AXI manager transaction-envelope metadata shipped?"
  - "what is the .ppif syntax for AXI manager transactions?"
  - "does transaction-envelope metadata change generated ISF FSM or HDL?"
  - "what sample covers AXI manager transaction-envelope metadata?"
  - "are AXI transaction envelopes structural or raw strings?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, transaction-envelope, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; ppif/axi_manager_capacity_status_transaction_envelope.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Adapter/IAL2/PPIF.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

AXI manager transaction-envelope metadata is shipped as an optional
`(transactions ...)` clause under the existing public
`manager-capacity-status` `.ppif` object.

The parser and generator normalize transactions to machine-readable structural
entries with `name`, `kind`, `tag`, `request_event`, `completion_event`, and
`id`; they do not preserve transactions as raw source-line strings.

Concrete transaction IDs validate against the matching declared read/write
ID-family width and presence. Report JSON additively emits `transactions[]`
under schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`.

The generated `.isf`, generated `.fsm`, and HDL remain unchanged by this
metadata slice. ID allocation, ordering, response matching, bursts,
queued/blocking policy, per-transaction event ports, full AXI manager
behavior, and VHDL remain future exact-owner work.
