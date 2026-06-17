---
id: ial2-axi-manager-read-burst-last-depth3-queue-head-response-demux-readiness-audit
title: IAL2 read burst-last depth-3 queue-head response-demux is ready for a narrow implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.155 select?"
  - "is read burst-last depth-3 queue-head response-demux ready to implement?"
  - "what blocks read burst-last depth-3 queue-head response-demux today?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, burst-last, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.155|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.156|read burst-last depth-3 concrete same-ID queue-head response-demux|AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.155` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.156`, generated read burst-last depth-3
concrete same-ID queue-head response-demux.

The temporary read burst-last depth-3 probe passes schedule parsing, strict
check JSON, and semantic JSON, but remains selected-not-generated with
`generated_same_id_queue_head_demux` residue. The only direct blocker found by
the audit is the local behavior-builder gate that currently admits depth-3
only for the read single-beat sibling.

The selected `.156` boundary is one read family, `response-scope burst-last`,
one-bit `RLAST`, exactly one duplicate concrete `RID` group of three read
transactions at computed depth `3`, generated queue-head response-demux only,
and no read-data, burst-length, runtime-validation, multi-beat, write depth-3,
multiple/mixed depth-3, mixed auto-ID, direct backend, or VHDL widening.
