---
id: ial2-axi-manager-write-same-id-queue-head-response-demux-behavior
title: AXI manager write same-ID queue-head response demux is generated for one depth-2 group
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.108 ship?"
  - "is write same-ID queue-head response demux generated?"
  - "what does generated_write_bid_queue_head_demux mean?"
  - "does FSMGen support write same-ID issue-order queue behavior?"
  - "what does the write same-ID queue-head sample report?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, write, response-demux, queue-head, generated-behavior]
evidence: docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif | rg 'generated_write_bid_queue_head_demux|accepted_same_id_reuse|generated_queue_behavior|axi0_w0_response_demux|axi0_w1_response_demux'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.108` shipped generated AXI write
same-ID queue-head response-demux behavior for the public sample
`ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif`.

The covered shape is exactly one duplicate concrete write-ID group of two
transactions at computed depth 2. FSMGen emits admitted write enqueue pulses,
compact one-hot write queue slot state, finite queue update rules, generated
write completion pulse outputs, and queue-head `BID` demux rules guarded by
the raw write response event, concrete `BID`, and slot-0 transaction bit.

The report boundary is `generated_write_bid_queue_head_demux`. For the covered
write shape, response demux and same-ID ordering both report generated
behavior, and the write same-ID policy reports `accepted_same_id_reuse: true`
and `generated_queue_behavior: true`.

The slice also repaired appended HDL assertion emission by inlining
assertion-only intermediate expressions in SVA conditions. Read `single-beat`,
deeper or multiple duplicate-ID groups, same-family mixed auto-ID plus
concrete queue-head demux, read-data consumption, direct backend lowering, and
VHDL remain deferred behind later task-tree owners.
