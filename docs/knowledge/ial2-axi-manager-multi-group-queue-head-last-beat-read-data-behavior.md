---
id: ial2-axi-manager-multi-group-queue-head-last-beat-read-data-behavior
title: IAL2 generated multi-group queue-head scalar last-beat read-data is shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.130 ship?"
  - "is scalar last-beat read-data over multiple queue-head groups supported?"
  - "which PPIF sample covers multi-group queue-head last-beat read-data?"
  - "what did the .130 no-burst multi-group scalar last-beat sample ship?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, last-beat, multi-group]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.130|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|read_multi_group_last_beat_same_id_queue_head_read_data|read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion|generated_queue_head_response_demux_last_beat_completion_pulse|burst_length_source: rlast_only|burst_length_validation: not_generated|burst_length_validation: runtime_assertion|multi-group queue-head scalar last-beat'
  docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.130` shipped generated scalar last-beat
read-data capture over multiple generated read burst-last concrete same-ID
queue-head groups.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`

The accepted boundary is generated read burst-last queue-head demux with two
or more depth-2 duplicate concrete read-ID groups, scalar `capture_scope
last-beat`, `completion-source response-demux`, `status-policy last-beat`,
`interleaving last-beat-by-rid`, no `burst_length` metadata, and complete
per-transaction scalar `data_output` / `status_output` bindings.

Live schedule JSON for the sample reports `read_data.mode:
bounded_last_beat_read_data_contract`, `capture_scope: last_beat`,
`completion_validity:
generated_queue_head_response_demux_last_beat_completion_pulse`,
`burst_length_source: rlast_only`, `burst_length_validation: not_generated`,
transactions `r0`, `r1`, `r2`, `r3`, eight generated scalar outputs, and four
generated capture rules. `response_demux.residue` remains
`read_data_interleaving, bursts`; `read_data.residue` remains the scalar
last-beat set for multi-beat reassembly, per-beat outputs, `RRESP`
aggregation, and `ARLEN` / beat-count validation.

Report-only raw-`ARLEN` multi-group scalar last-beat capture is shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.132` in
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`.
Runtime beat-count/`RLAST` multi-group scalar last-beat validation is shipped
by `IAL2-FEATURE-COMPLETENESS-FRONTIER.135` in
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`.
