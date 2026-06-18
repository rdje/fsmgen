---
id: ial2-axi-manager-post-multiple-mixed-depth3-read-data-next-slice
title: Burst-last read-data readiness follows multiple/mixed depth-3 single-beat read-data
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.178 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 read-data?"
  - "why is burst-last read-data next after multiple/mixed depth-3 single-beat read-data?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, queue-head, depth-3, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.178|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.179|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION|read burst-last scalar last-beat read-data over multiple or mixed depth-3' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.178` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.179`, readiness audit for generated read
burst-last scalar last-beat read-data over multiple or mixed depth-3 concrete
same-ID queue-head groups.

The selector is documentation-only. It records that `.177` now generates read
single-beat scalar read-data over multiple/mixed depth-3 queue-head groups,
that `.174` already generates adjacent read burst-last multiple/mixed depth-3
response-demux-only groups, and that the one-group depth-3 read burst-last
scalar read-data path is generated.

Temporary read burst-last last-beat read-data candidates over two-depth-3 and
mixed depth-3/depth-2 queue-head groups still fail closed at the local
`_read_data_response_demux_transaction_coverage` last-beat coverage gate.
The `.179` audit must decide whether the local gate can be widened directly
for scalar last-beat read-data before burst-length, runtime-validation,
multi-beat payload, write-family read-data, mixed auto-ID, direct backend,
verification-output generation, VHDL, or backend-language variants.
