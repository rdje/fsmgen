---
id: ial2-axi-manager-read-single-beat-depth3-queue-head-read-data-behavior
title: AXI manager supports one generated read single-beat depth-3 queue-head read-data shape
answers:
  - "does AXI manager read-data support read single-beat depth-3 queue-head demux?"
  - "which PPIF sample covers read single-beat depth-3 queue-head read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.153 ship?"
  - "what remains deferred after depth-3 queue-head read-data?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, read-data, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.153|axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data|generated_queue_head_response_demux_completion_pulse|exactly one generated depth-3 read group' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md
  README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.153` shipped generated scalar read-data
over one read single-beat depth-3 concrete same-ID queue-head response-demux
group.

The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif`.
It has one generated read single-beat queue-head group where `r0`, `r1`, and
`r2` share concrete `RID` `3`; the computed queue depth is `3`.

The generated read-data report uses
`completion_validity: generated_queue_head_response_demux_completion_pulse`,
declares generated `axi0_rdata` and `axi0_rresp` inputs, and emits scalar
`RDATA`/`RRESP` capture rules for `r0`, `r1`, and `r2` guarded by the generated
queue-head completion pulses.

Strict check JSON and semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data`.
Read burst-last depth-3 response-demux, write depth-3 response-demux,
multiple or mixed depth-3 groups, same-family mixed auto-ID, group-local
enqueue widening, packed outputs, direct backend, and VHDL remain deferred.
