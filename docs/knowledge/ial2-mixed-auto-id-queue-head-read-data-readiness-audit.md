---
id: ial2-mixed-auto-id-queue-head-read-data-readiness-audit
title: Mixed auto-ID queue-head read-data readiness selects scalar implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.196 select?"
  - "why is IAL2-FEATURE-COMPLETENESS-FRONTIER.197 safe?"
  - "what diagnostic blocks mixed auto-id queue-head read-data?"
  - "which mixed read-data shapes are selected next?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, read-data, audit]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.196|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.197|read_data\\.read transaction .r1. is not covered|mixed scalar read-data|generated_demux_and_queue_head_demux' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.196` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.197`, direct bounded implementation of
scalar read-data consumption over same-family mixed auto-ID lifecycle plus
concrete same-ID queue-head response-demux.

Temporary read single-beat and read burst-last mixed read-data probes using
existing syntax both fail closed at the local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read transaction 'r1' is not covered by generated read response_demux auto transactions
```

The failure shows the current read-data coverage helper treats the mixed
`generated_demux_and_queue_head_demux` source as auto-ID-only. Once coverage
admits the combined auto-ID plus concrete queue-head transaction/completion
list, scalar capture rules and report artifacts are already transaction-list
driven.

`.197` should cover read single-beat scalar `RDATA`/`RRESP` and read
burst-last scalar last-beat `RDATA`/`RRESP` only. Mixed multi-beat, burst
length/runtime validation, group-local enqueue widening, write-family
read-data, packed outputs, direct backend, verification-output generation,
VHDL, and backend-language variants remain out of scope.
