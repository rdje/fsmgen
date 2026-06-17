---
id: ial2-axi-manager-read-burst-last-depth3-queue-head-burst-length-behavior
title: AXI manager read burst-last depth-3 queue-head read-data supports report-only raw ARLEN
answers:
  - "does AXI manager read burst-last depth-3 queue-head read-data support report-only ARLEN?"
  - "which PPIF sample covers read burst-last depth-3 queue-head burst-length?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.162 ship?"
  - "does read burst-last depth-3 report-only burst-length generate beat counters?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, same-id, queue-head, read-data, burst-last, depth-3, arlen, burst-length]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif && env -u PERL5LIB ./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif && env -u PERL5LIB ./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.162|read_burst_last_depth3_same_id_queue_head_burst_length|generated_burst_length_storage|burst_length_validation: report_only|generated_beat_count_validation|AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/REGRESSION_CORPUS.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.162` shipped generated report-only
raw-`ARLEN` burst-length capture over one read burst-last depth-3 concrete
same-ID queue-head read-data group.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif`

The accepted boundary is generated read burst-last queue-head demux for one
duplicate concrete read-ID group where `r0`, `r1`, and `r2` share concrete
`RID` `3` at computed depth `3`; scalar `capture_scope last-beat`;
`completion-source response-demux`; `status-policy last-beat`;
`interleaving last-beat-by-rid`; and `burst_length` metadata with `source
arlen`, `signal` width `8`, `encoding axlen-plus-one`, `capture request`,
`max-beats 16`, and `validation report-only`.

Live schedule JSON for the sample reports `read_data.mode:
bounded_last_beat_read_data_contract`, `completion_validity:
generated_queue_head_response_demux_last_beat_completion_pulse`,
`burst_length_validation: report_only`, generated burst-length input
`axi0_arlen`, generated raw-`ARLEN` storage `axi0_r0_arlen_q`,
`axi0_r1_arlen_q`, and `axi0_r2_arlen_q`, and generated burst-length rules
`axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
`axi0_r2_burst_length_capture`.

Because validation is report-only, the shape does not generate expected-beat
storage, matched-beat counters, or beat-count/`RLAST` runtime assertions.
Runtime validation, multi-beat output-bank behavior over read burst-last
depth-3, write depth-3, multiple or mixed depth-3 groups, mixed auto-ID,
direct backend, and VHDL remain deferred.
