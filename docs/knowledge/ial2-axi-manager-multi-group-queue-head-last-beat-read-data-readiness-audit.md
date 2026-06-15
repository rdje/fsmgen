---
id: ial2-axi-manager-multi-group-queue-head-last-beat-read-data-readiness-audit
title: IAL2 multi-group queue-head last-beat read-data audit selects scalar implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.129 select?"
  - "what is the next slice after the multi-group last-beat read-data audit?"
  - "is last-beat read-data over multiple queue-head groups ready?"
  - "why did the multi-group raw-ARLEN and runtime-validation variants need later owners?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, last-beat, audit]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.129|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.130|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.132|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|multi-group queue-head last-beat read-data|last-beat read-data over multiple generated read burst-last concrete same-ID queue-head groups|burst_length|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.129` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.130`, generated multi-group queue-head
last-beat read-data capture.

The `.129` audit is documentation-only. It changes no parser, generator,
PPIF sample, support-accounting, test, generated artifact, or HDL behavior.

At the time of the `.129` audit, the implementation still failed closed for
scalar last-beat read-data over two generated read burst-last queue-head
groups with:

```text
AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice
```

The `.130` boundary should permit two or more generated read burst-last
depth-2 queue-head groups only for scalar `capture_scope last-beat`,
`completion-source response-demux`, `status-policy last-beat`,
`interleaving last-beat-by-rid`, no `burst_length` metadata, and complete
per-transaction `data_output`/`status_output` bindings.

The `.130` implementation later shipped the no-`burst_length` scalar
last-beat behavior, `.132` shipped the report-only raw-`ARLEN` sibling, and
`.135` shipped the runtime beat-count/`RLAST` sibling. Those follow-ups were
kept as separate owners because they generate additional per-transaction
burst-length storage, count state, and assertions beyond scalar last-beat
capture.
