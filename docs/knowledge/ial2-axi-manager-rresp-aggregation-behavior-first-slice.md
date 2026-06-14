---
id: ial2-axi-manager-rresp-aggregation-behavior-first-slice
title: AXI scalar RRESP aggregation behavior is generated
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.79?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.79 ship?"
  - "does FSMGEN generate scalar RRESP aggregate outputs?"
  - "how does generated AXI scalar RRESP aggregation behave?"
  - "what does status_aggregation_generated_behavior true mean?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, behavior, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.79|RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE|status_aggregation_generated_behavior|generated_status_aggregate_outputs|generated_status_aggregate_init_rules|generated_status_aggregate_update_rules|axi0_r0_rresp_aggregate|residue: \\[\\]' docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.79` ships generated scalar AXI
multi-beat `RRESP` aggregation behavior for the selected width-2
`worst_observed` contract.

For each read transaction with a `status_aggregate_output`, FSMGEN emits one
width-2 scalar aggregate output, initializes it to `2'd0` on the transaction
request in the existing output-bank init rule, and updates it on accepted
matched read-data beats when the current aggregate is less than the current
`RRESP` signal under the existing `!request_event` boundary.

Schedule JSON reports `status_aggregation_generated_behavior: true`,
`generated_status_aggregate_outputs`,
`generated_status_aggregate_init_rules`, and
`generated_status_aggregate_update_rules`. The selected multi-beat sample no
longer reports `generated_rresp_aggregation` in `read_data.residue`.

No-aggregation multi-beat contracts remain valid and continue to report
`status_aggregation: none` with `read_data.residue: [rresp_aggregation]`.
