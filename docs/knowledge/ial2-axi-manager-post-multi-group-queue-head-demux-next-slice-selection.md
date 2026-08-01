---
id: ial2-axi-manager-post-multi-group-queue-head-demux-next-slice-selection
title: IAL2 selects a read-data-over-multiple-queue-groups readiness audit after multi-group queue-head demux
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.125 select?"
  - "what is the next slice after multi-group queue-head response-demux?"
  - "does the next IAL2 slice implement read-data over multiple queue groups?"
  - "why is read-data over multiple queue groups an audit first?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.125|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.126|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.127|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.128|read-data coverage over multiple generated read burst-last concrete same-ID queue-head groups|generated multi-group queue-head multi-beat read-data output-bank behavior|read_multi_group_same_id_queue_head_read_data|_read_data_response_demux_transaction_coverage' docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.125` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.126`, a readiness audit for read-data
coverage over multiple generated read burst-last concrete same-ID queue-head
groups.

The selector did not implement behavior. The current generated `.124` sample
has multiple generated queue groups but no `read_data` clause, while the `.121`
queue-head multi-beat read-data sample proves read-data only for one generated
queue group.

The local blocker was `_read_data_response_demux_transaction_coverage`, which
required exactly one depth-2 concrete same-ID read queue group before
queue-head read-data was accepted. The `.126` audit selected `.127`, generated
multi-group queue-head multi-beat read-data output-bank behavior. `.127` later
shipped that selected behavior for the separate support-accounted sample and
advanced the frontier to `.128`. Last-beat-only/report-only/runtime-only
multi-group read-data remains deferred outside that selected multi-beat
output-bank shape.
