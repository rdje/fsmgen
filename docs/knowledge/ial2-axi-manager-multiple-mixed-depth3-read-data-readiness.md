---
id: ial2-axi-manager-multiple-mixed-depth3-read-data-readiness
title: Multiple/mixed depth-3 queue-head read-data selected single-beat first
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.176 select?"
  - "what is the next IAL2 frontier after the multiple/mixed depth-3 read-data audit?"
  - "is read single-beat data over multiple or mixed depth-3 queue-head groups selected?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.176|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.177|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT|read single-beat scalar|_read_data_response_demux_transaction_coverage' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.176` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.177`, direct bounded implementation of
generated read single-beat scalar `RDATA`/`RRESP` over multiple or mixed
depth-3 concrete same-ID queue-head groups.

The audit found the implementation blocker is local to the single-beat branch
of `_read_data_response_demux_transaction_coverage`. Existing read
single-beat depth-2 multi-group and one-depth-3 read-data samples generate,
while temporary two-depth-3 and mixed depth-3/depth-2 read-data candidates
fail closed at the current coverage gate.

`.177` must not enable burst-last read-data, burst-length,
runtime-validation, multi-beat payload, write-family read-data, mixed
auto-ID, direct backend, VHDL, or backend-language variants.
