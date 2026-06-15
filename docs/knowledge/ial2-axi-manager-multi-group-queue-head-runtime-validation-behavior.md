---
id: ial2-axi-manager-multi-group-queue-head-runtime-validation-behavior
title: IAL2 multi-group queue-head scalar runtime validation is shipped
answers:
  - "does FSMGen support multi-group queue-head scalar runtime validation?"
  - "which PPIF sample covers multi-group queue-head runtime validation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.135 ship?"
  - "does multi-group scalar queue-head runtime validation remove generated_beat_count_validation residue?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, read-data, same-id, last-beat, multi-group, runtime-validation]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; perl/FSM/Support/RegressionCorpus.pm; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.135|read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion|runtime_assertion|generated_expected_beat_storage|generated_beat_count_storage|multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation|AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.135` shipped generated
runtime-validation behavior for multi-group queue-head scalar last-beat
read-data.

The public support-accounted sample is:

- `ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`

The accepted boundary is generated read burst-last queue-head demux with two
or more depth-2 duplicate concrete read-ID groups, scalar `capture_scope
last-beat`, `completion-source response-demux`, `status-policy last-beat`,
`interleaving last-beat-by-rid`, `burst_length` metadata with `source arlen`,
`signal` width `8`, `encoding axlen-plus-one`, `capture request`,
`validation runtime-assertion`, and complete per-transaction scalar outputs.

The generated path emits raw-`ARLEN` storage, expected-beat storage, matched
read-beat counters, request-time init rules, matched-beat increment rules, and
four beat-count/`RLAST` assertions per covered transaction across `r0`, `r1`,
`r2`, and `r3`. The schedule report records `burst_length_validation:
runtime_assertion`, `beat_count_validation_generated_behavior: true`, and
removes `generated_beat_count_validation` from `read_data.residue` for this
bounded sample.
