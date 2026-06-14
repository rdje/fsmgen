---
id: ial2-axi-manager-same-id-queue-head-demux-metadata
title: Same-ID queue-head demux metadata is selected-not-generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.103 ship?"
  - "is AXI same-ID queue-head response demux generated?"
  - "what does the same-ID queue-head response-demux sample report?"
  - "what happened after IAL2-FEATURE-COMPLETENESS-FRONTIER.104?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, metadata, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md; ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif | rg 'bounded_read_rid_queue_head_demux_contract|selected_not_generated|generated_queue_head_demux|compact_onehot_transaction_slots|accepted_same_id_reuse|generated_queue_behavior'
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.103` shipped selected-not-generated
metadata and static validation for AXI concrete same-ID queue-head response
demux.

The public sample is
`ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif`.
It reports `bounded_read_rid_queue_head_demux_contract`,
`implementation_status: selected_not_generated`,
`transaction_completion_source: generated_queue_head_demux`,
`queue_state_representation: compact_onehot_transaction_slots`, and one
duplicate concrete-ID queue group for read transactions `r0` and `r1`.

Generated queue state and queue-head demux rules are not shipped yet.
`accepted_same_id_reuse` and `generated_queue_behavior` remain false, and
read-data consumption of this selected-not-generated demux fails closed.

`.104` audited generated queue state and queue-head behavior readiness. It
found no obvious new lower-layer substrate prerequisite, but direct broad
implementation remains too large because queue state and queue-head demux must
be specified together. The next active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated behavior slice
selection.
