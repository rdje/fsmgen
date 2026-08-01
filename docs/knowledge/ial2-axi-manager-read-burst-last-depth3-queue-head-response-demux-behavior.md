---
id: ial2-axi-manager-read-burst-last-depth3-queue-head-response-demux-behavior
title: AXI manager supports one generated read burst-last depth-3 queue-head response-demux shape
answers:
  - "does AXI manager support read burst-last depth-3 queue-head response-demux?"
  - "which PPIF sample covers read burst-last depth-3 queue-head response-demux?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.156 ship?"
  - "what remains deferred after read burst-last depth-3 response-demux?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, burst-last, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif && env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.156|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux|generated_read_burst_last_queue_head_demux|selected single-group read burst-last depth-3 response-demux-only and scalar last-beat read-data queue-head shapes'
  docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.156` shipped generated read burst-last
response-demux over one depth-3 concrete same-ID queue-head group.

The public sample is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif`.
It has one generated read burst-last queue-head group where `r0`, `r1`, and
`r2` share concrete `RID` `3`; the computed queue depth is `3`.

The generated report marks
`generated_read_burst_last_queue_head_demux`, emits generated `axi0_rid` and
`axi0_rlast` inputs, compact queue storage through `slot2`, completion pulses
for `r0`, `r1`, and `r2`, and response-demux rules guarded by raw read
completion, concrete `RID`, `RLAST`, and slot0 identity.

Strict check JSON and semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux`.
Read-data over read burst-last depth-3, burst-length/runtime or multi-beat
over read burst-last depth-3, write depth-3, multiple or mixed depth-3 groups,
same-family mixed auto-ID, group-local enqueue widening, packed outputs,
direct backend, and VHDL remain deferred.
