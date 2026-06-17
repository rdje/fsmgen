---
id: ial2-axi-manager-read-burst-last-depth3-queue-head-read-data-behavior
title: AXI manager supports one generated read burst-last depth-3 queue-head read-data shape
answers:
  - "does AXI manager read-data support read burst-last depth-3 queue-head demux?"
  - "which PPIF sample covers read burst-last depth-3 queue-head read-data?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.159 ship?"
  - "what remains deferred after read burst-last depth-3 queue-head read-data?"
  - "does read burst-last depth-3 queue-head read-data now have a burst-length sibling?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, read-data, burst-last, depth-3]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif && env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.159|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.162|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data|axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length|generated_queue_head_response_demux_last_beat_completion_pulse|selected single depth-3 queue-head group with no burst_length metadata or report-only raw-ARLEN burst-length metadata' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.159` shipped generated scalar last-beat
read-data over one read burst-last depth-3 concrete same-ID queue-head
response-demux group.

The public sample is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif`.
It has one generated read burst-last queue-head group where `r0`, `r1`, and
`r2` share concrete `RID` `3`; the computed queue depth is `3`.

The generated read-data report uses
`completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`,
declares generated `axi0_rdata` and `axi0_rresp` inputs, and emits scalar
last-beat `RDATA`/`RRESP` capture rules for `r0`, `r1`, and `r2` guarded by
the generated `RID`/`RLAST` queue-head completion pulses.

Strict check JSON and semantic JSON support-account the no-`burst_length`
sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data`.
The report-only raw-`ARLEN` burst-length sibling is now shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.162` in
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif`.
Runtime-validation and multi-beat behavior over read burst-last depth-3,
write depth-3 response-demux, multiple or mixed depth-3 groups, same-family
mixed auto-ID, group-local enqueue widening, packed outputs, direct backend,
and VHDL remain deferred.
