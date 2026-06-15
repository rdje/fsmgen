---
id: ial2-axi-manager-multi-group-queue-head-read-data-behavior
title: IAL2 multi-group queue-head multi-beat read-data behavior is shipped
answers:
  - "does FSMGen generate read-data over multiple queue-head groups?"
  - "which PPIF sample covers multi-group queue-head read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.127 ship?"
  - "what is the completion validity for multi-group queue-head read-data?"
  - "what remains deferred after multi-group queue-head read-data?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, multi-beat, output-bank]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.127|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.128|read_multi_group_same_id_queue_head_read_data|generated multi-group queue-head multi-beat read-data|generated_queue_head_response_demux_last_beat_completion_pulse|per_beat_output_bank|response_demux_matched_read_beat|read_data\\.residue: \\[\\]' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.127` shipped generated multi-group
queue-head multi-beat read-data output-bank behavior.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
It combines generated read burst-last concrete same-ID queue-head demux with
two generated depth-2 groups: `r0`/`r1` on `RID` `3`, and `r2`/`r3` on
`RID` `5`.

FSMGen flattens the generated queue groups into read-data coverage for the
selected multi-beat shape, emits per-transaction output-bank clearing,
`RDATA`/`RRESP` lane capture, valid-mask and length outputs, scalar `RRESP`
aggregation, raw `ARLEN` capture, and beat-count/`RLAST` runtime validation.

The sample reports `completion_validity:
generated_queue_head_response_demux_last_beat_completion_pulse`,
`beat_match_source: response_demux_matched_read_beat`, `output_shape:
per_beat_output_bank`, and empty `read_data`/`response_demux` residue.

Last-beat-only multi-group read-data, report-only/runtime-only multi-group
variants outside the selected multi-beat output-bank shape, same-family mixed
auto-ID, deeper queues, write/read-single-beat multi-group queue-head behavior,
packed outputs, direct backend, and VHDL remain deferred.
