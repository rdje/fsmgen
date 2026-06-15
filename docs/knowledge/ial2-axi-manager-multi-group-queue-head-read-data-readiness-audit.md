---
id: ial2-axi-manager-multi-group-queue-head-read-data-readiness-audit
title: IAL2 selects multi-group queue-head multi-beat read-data behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.126 select?"
  - "what is the next slice after the multi-group queue-head read-data readiness audit?"
  - "can FSMGen generate read-data over multiple queue-head groups?"
  - "why is multi-group queue-head read-data limited to multi-beat first?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, multi-beat, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.126|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.127|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.128|generated multi-group queue-head multi-beat read-data output-bank behavior|read_multi_group_same_id_queue_head_read_data|_read_data_response_demux_transaction_coverage|response_demux_matched_read_beat|per_beat_output_bank' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.126` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.127`, generated multi-group queue-head
multi-beat read-data output-bank behavior.

The audit did not implement behavior. It confirmed that the current
fail-closed blocker is the exact-one-group guard in
`_read_data_response_demux_transaction_coverage`.

The next implementation should flatten all generated read burst-last
queue-head groups into read-data coverage only for the selected multi-beat
output-bank shape, preserving one generated last-beat completion signal per
transaction, matched-read-beat lookup by transaction, per-beat output banks,
valid-mask and length outputs, scalar `RRESP` aggregation, and beat-count /
`RLAST` runtime validation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.127` later shipped that selected
multi-beat output-bank behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`
and advanced the frontier to `.128`.

Last-beat-only multi-group read-data, report-only/runtime-only multi-group
variants outside the selected multi-beat output-bank shape, same-family mixed
auto-ID, deeper queues, write/read-single-beat multi-group queue-head
behavior, packed outputs, direct backend, and VHDL remain deferred.
