---
id: ial2-mixed-auto-id-queue-head-read-data-behavior
title: Mixed auto-ID queue-head read-data ships for bounded read shapes
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.197 ship?"
  - "is mixed auto-id plus queue-head read-data supported?"
  - "which PPIF samples cover mixed auto-id queue-head read-data?"
  - "what completion validity does mixed queue-head read-data report?"
date: 2026-06-21
status: current
tags: [ial2, axi, manager, auto-id, same-id, queue-head, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.197|MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR|generated_mixed_auto_id_queue_head_response_demux_completion_pulse|generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse|read_single_beat_mixed_auto_id_same_id_queue_head_read_data|read_burst_last_mixed_auto_id_same_id_queue_head_read_data|generated_demux_and_queue_head_demux' docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.197` shipped bounded scalar read-data
consumption over same-family mixed auto-ID lifecycle plus concrete same-ID
queue-head response-demux for two read shapes:

- `ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif`

Both samples use existing syntax. They contain one auto-ID read transaction
`r0`, one concrete depth-2 same-ID queue group for `r1`/`r2`, and read-data
bindings for all three transactions.

The generated read-data reports use the mixed response-demux source
`generated_demux_and_queue_head_demux` and transaction coverage `r0,r1,r2`.
Single-beat capture reports
`generated_mixed_auto_id_queue_head_response_demux_completion_pulse`; burst-last
last-beat capture reports
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`.

Mixed multi-beat read-data, burst-length/runtime validation over mixed
families, group-local enqueue widening, write-family read-data, packed
outputs, direct backend, verification-output generation, VHDL, and
backend-language variants remain separately owned.
