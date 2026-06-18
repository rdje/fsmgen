---
id: ial2-axi-manager-post-multiple-mixed-depth3-response-demux-next-slice
title: Read-data over multiple/mixed depth-3 queue-head groups is the next audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.175 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 response-demux?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, read-data, queue-head, depth-3, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.175|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.176|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|read-data over multiple or mixed depth-3|_read_data_response_demux_transaction_coverage' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.175` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.176`, readiness audit for generated
read-data over multiple or mixed depth-3 concrete same-ID queue-head groups.

The selector is documentation-only. It records that `.174` now generates the
multiple/mixed depth-3 response-demux-only queue-head groups, while temporary
read single-beat and read burst-last read-data probes over two depth-3 queue
groups fail closed at `_read_data_response_demux_transaction_coverage`.

`.176` must decide whether the next behavior owner should start with
single-beat scalar read-data, scalar single-beat plus last-beat, or a broader
read-data subset. Same-family mixed auto-ID, group-local enqueue widening,
packed outputs, alternate burst assembly, direct backend, verification-output
generation, VHDL, and backend-language variants remain future exact-owner
work.
