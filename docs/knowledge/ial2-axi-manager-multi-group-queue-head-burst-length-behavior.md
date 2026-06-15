---
id: ial2-axi-manager-multi-group-queue-head-burst-length-behavior
title: IAL2 multi-group queue-head scalar last-beat read-data supports report-only raw ARLEN
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.132 ship?"
  - "is multi-group queue-head scalar last-beat report-only ARLEN supported?"
  - "which PPIF sample covers multi-group queue-head burst-length capture?"
  - "does multi-group scalar queue-head report-only burst-length generate beat counters?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, last-beat, multi-group, arlen, burst-length]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.132|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|read_multi_group_last_beat_same_id_queue_head_burst_length|generated_burst_length_storage|burst_length_validation: report_only|runtime-validation sibling|AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.132` shipped generated report-only
raw-`ARLEN` burst-length capture for multi-group queue-head scalar last-beat
read-data.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`

The accepted boundary is generated read burst-last queue-head demux with two
or more depth-2 duplicate concrete read-ID groups, scalar `capture_scope
last-beat`, `completion-source response-demux`, `status-policy last-beat`,
`interleaving last-beat-by-rid`, `burst_length` metadata with `source arlen`,
`signal` width `8`, `encoding axlen-plus-one`, `capture request`,
`validation report-only`, and complete per-transaction scalar outputs.

Live schedule JSON for the sample reports `read_data.mode:
bounded_last_beat_read_data_contract`, `capture_scope: last_beat`,
`burst_length_validation: report_only`, generated burst-length input
`axi0_arlen`, generated raw-`ARLEN` storage `axi0_r0_arlen_q` through
`axi0_r3_arlen_q`, generated burst-length rules
`axi0_r0_burst_length_capture` through `axi0_r3_burst_length_capture`, and
scalar read-data capture rules for `r0`, `r1`, `r2`, and `r3`.

Because validation is report-only, the shape does not generate expected-beat
storage, matched-beat counters, or beat-count/`RLAST` runtime assertions.
The runtime-validation sibling for the same multi-group scalar shape is now
shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.135` in
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`.
