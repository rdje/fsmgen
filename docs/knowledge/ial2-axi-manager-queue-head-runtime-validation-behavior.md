---
id: ial2-axi-manager-queue-head-runtime-validation-behavior
title: Queue-head last-beat read-data supports beat-count/RLAST runtime validation
answers:
  - "does queue-head burst-length support runtime validation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.119 ship?"
  - "which PPIF sample covers queue-head runtime validation?"
  - "how does queue-head runtime validation count read beats?"
  - "what comes after queue-head runtime validation?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, read-data, queue-head, burst-length, rlast, runtime-validation]
evidence: docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.119|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.120|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.121|queue-head runtime|queue-head multi-beat|runtime_assertion|beat_count_match_source|response_demux_matched_read_beat|generated_queue_head_response_demux_last_beat_completion_pulse' docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.119` shipped generated
beat-count/`RLAST` runtime validation for the bounded read burst-last
concrete same-ID queue-head last-beat read-data burst-length shape.

The public support-accounted sample is
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`.
It combines the `.117` queue-head burst-length shape with
`validation runtime-assertion`.

FSMGen keeps request-bound raw-`ARLEN` capture and queue-head last-beat
`RDATA`/`RRESP` capture. It adds expected-beat storage, matched-read-beat
counters, initialization and increment rules, and runtime assertions for
request-time `ARLEN` bound, over-count or extra beats, early `RLAST`, and
missing final `RLAST`.

The beat-count match source is `response_demux_matched_read_beat`: raw read
response event plus concrete `RID` plus active queue-head transaction
identity. It intentionally does not use the `RLAST`-qualified completion
pulse, while the read-data capture completion validity remains
`generated_queue_head_response_demux_last_beat_completion_pulse`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.120` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.121`, generated multi-beat read-data
output-bank behavior for the bounded read burst-last concrete same-ID
queue-head demux shape. Deeper or multiple queue groups, mixed auto-ID,
direct backend, and VHDL remain deferred.
