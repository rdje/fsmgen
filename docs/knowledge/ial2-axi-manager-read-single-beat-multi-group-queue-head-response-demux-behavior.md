---
id: ial2-axi-manager-read-single-beat-multi-group-queue-head-response-demux-behavior
title: IAL2 read single-beat multi-group queue-head response-demux behavior is shipped
answers:
  - "does FSMGen support read single-beat multi-group queue-head response-demux?"
  - "which PPIF sample covers read single-beat multi-group queue-head response-demux?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.143 ship?"
  - "does read single-beat multi-group queue-head response-demux include read-data?"
  - "is read single-beat multi-group queue-head response-demux visible through semantic JSON?"
  - "what is the next IAL2 PNT frontier after read single-beat multi-group behavior?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, same-id, response-demux, semantic-json, mcp, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.143|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.144|read_single_beat_multi_group_same_id_queue_head_response_demux|generated_read_single_beat_queue_head_demux|multiple read single-beat response-demux-only queue groups|Support Accounting And Semantic Introspection' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md
  docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.143` shipped generated read single-beat
response-demux-only queue-head behavior for multiple independent duplicate
concrete read-ID groups.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`.
It has two generated depth-2 groups: `r0`/`r1` share concrete `RID` `3`, and
`r2`/`r3` share concrete `RID` `5`.

FSMGen emits concrete-ID-scoped compact one-hot queue storage, finite depth-2
transition rules, generated completion pulse outputs, `RID`-qualified
queue-head response-demux rules without `RLAST`, queue assertions, response-
demux assertions, and generated queue reports for both groups. The existing
family-wide admitted-request onehot boundary remains the enqueue contract.

The `.143` sample is response-demux-only. It intentionally has no
`last-signal` and no `read_data` clause. The later `.146` sample ships the
bounded read-data sibling for multiple read single-beat queue-head groups.

Strict check JSON and normalized semantic JSON match the support-accounting
entry
`intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux`,
so MCP-facing deep semantic introspection sees the same support claim as the
public corpus catalog. After `.143`, the PNT frontier advanced to `.144`; at
that point, the IAL2 frontier after `.147` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.148`.
