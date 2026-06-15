---
id: ial2-axi-manager-multi-group-queue-head-response-demux-behavior
title: IAL2 multi-group queue-head response-demux behavior is shipped and multi-beat read-data now has a separate sample
answers:
  - "does FSMGen support multiple concrete read-ID queue-head response-demux groups?"
  - "which PPIF sample covers multi-group queue-head response-demux?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.124 ship?"
  - "does multi-group queue-head response-demux include read-data?"
  - "what is the next IAL2 PNT frontier after multi-group queue-head demux?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, same-id, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif; ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.124|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.127|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.128|read_multi_group_same_id_queue_head_response_demux|read_multi_group_same_id_queue_head_read_data|multiple independent read burst-last response-demux-only queue groups|generated multi-group queue-head multi-beat read-data output-bank behavior' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.124` shipped generated read burst-last
response-demux-only queue-head behavior for multiple independent duplicate
concrete read-ID groups.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`.
It has two generated depth-2 groups: `r0`/`r1` share concrete `RID` `3`, and
`r2`/`r3` share concrete `RID` `5`.

FSMGen emits concrete-ID-scoped compact one-hot queue storage, finite depth-2
transition rules, generated completion pulse outputs, `RLAST`-qualified
queue-head response-demux rules, queue assertions, response-demux assertions,
and generated queue reports for both groups. The existing family-wide
admitted-request onehot boundary remains the enqueue contract.

The `.124` sample is response-demux-only. `.127` later added a separate
support-accounted multi-group queue-head multi-beat read-data sample:
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
That sample flattens the generated `RID` `3` and `RID` `5` queue groups into
multi-beat read-data coverage and reports empty `read_data`/`response_demux`
residue.

Same-family auto-ID plus concrete queue-head demux, deeper queues, write or
read single-beat multiple-group queue-head behavior, packed outputs, direct
backend lowering, and VHDL remain deferred. After `.127`, the active PNT
frontier is `IAL2-FEATURE-COMPLETENESS-FRONTIER.128`, the next selector/audit.
