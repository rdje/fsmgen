---
id: ial2-axi-manager-multiple-mixed-depth3-multi-beat-read-data-behavior
title: Multiple/mixed depth-3 runtime queue-head multi-beat output banks ship
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.191 ship?"
  - "does FSMGen support multi-beat output banks over multiple/mixed depth-3 queue-head runtime-validation groups?"
  - "which PPIF samples cover multiple/mixed depth-3 queue-head multi-beat read-data?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 multi-beat output banks?"
date: 2026-06-19
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, multi-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif; ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.191|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.192|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR|read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data|read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data|runtime-assertion multi-beat output-bank' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.191` shipped generated multi-beat
read-data output-bank behavior over the two bounded multiple/mixed depth-3
read burst-last queue-head runtime-validation shapes selected by `.190`.

The public PPIF samples are
`ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif`.

The generated reports use `bounded_multi_beat_read_data_contract`,
`per_beat_output_bank`, runtime-assertion `ARLEN` validation, generated
queue-head last-beat completion validity, empty `read_data.residue`, and empty
`response_demux.residue`. The next frontier is `.192`, a selector for the
next exact IAL2 feature-completeness slice after this behavior.
