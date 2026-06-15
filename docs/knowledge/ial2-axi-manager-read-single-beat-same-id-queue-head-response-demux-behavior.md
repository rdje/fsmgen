---
id: ial2-axi-manager-read-single-beat-same-id-queue-head-response-demux-behavior
title: AXI manager read single-beat same-ID queue-head response demux is generated for one depth-2 group
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.110 ship?"
  - "is read single-beat same-ID queue-head response demux generated?"
  - "what does generated_read_single_beat_queue_head_demux mean?"
  - "does FSMGen support read single-beat same-ID issue-order queue behavior?"
  - "what does the read single-beat same-ID queue-head sample report?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, same-id, read, single-beat, response-demux, queue-head, generated-behavior]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif | rg 'generated_read_single_beat_queue_head_demux|accepted_same_id_reuse|generated_queue_behavior|axi0_r0_response_demux|axi0_r1_response_demux'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.110` shipped generated AXI read
single-beat same-ID queue-head response-demux behavior for the public sample
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif`.

The covered shape is exactly one duplicate concrete read-ID group of two
transactions at computed depth 2. FSMGen emits admitted read enqueue pulses,
compact one-hot read queue slot state, finite queue update rules, generated
read completion pulse outputs, and queue-head `RID` demux rules guarded by the
raw read response event, concrete `RID`, and slot-0 transaction bit. No
`RLAST` signal is generated or consumed for this single-beat shape.

The report boundary is `generated_read_single_beat_queue_head_demux`. For the
covered read single-beat shape, response demux and same-ID ordering both
report generated behavior, and the read same-ID policy reports
`accepted_same_id_reuse: true` and `generated_queue_behavior: true`.

Read-data consumption of concrete queue-head demux, deeper or multiple
duplicate-ID groups, same-family mixed auto-ID plus concrete queue-head demux,
generalized per-ID queues, direct backend lowering, and VHDL remain deferred
behind later task-tree owners.
