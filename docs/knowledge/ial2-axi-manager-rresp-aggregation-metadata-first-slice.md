---
id: ial2-axi-manager-rresp-aggregation-metadata-first-slice
title: AXI scalar RRESP aggregation metadata is parsed and reported
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.77?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.77 ship?"
  - "how is AXI scalar RRESP aggregation reported?"
  - "does FSMGEN generate scalar RRESP aggregate outputs yet?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.77?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, rresp, aggregation, metadata, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.77|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.78|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.79|status_aggregation_generated_behavior|generated_rresp_aggregation|status-aggregate-output|status_aggregate_output' docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md ppif/axi_manager_capacity_status_read_data_multi_beat.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.77` shipped parser/report metadata and
static validation for the selected AXI multi-beat scalar `RRESP` aggregation
contract.

The public `.ppif` parser accepts read-level
`(status-aggregation (policy worst-observed))` only for multi-beat read-data,
and requires one transaction-local `(status-aggregate-output NAME)` binding
per read transaction when aggregation is selected. The in-process normalizer
enforces the same contract and includes aggregate output names in generated
name collision checks.

Schedule JSON reports `status_aggregation: worst_observed`,
`status_aggregation_generated_behavior: false`,
`status_aggregate_output: per_transaction_scalar`,
`status_aggregate_output_width: 2`, per-transaction scalar output names and
widths, and `read_data.residue: [generated_rresp_aggregation]`.

`.77` does not generate scalar aggregate outputs or update rules. Existing
generated multi-beat output-bank `.isf`, `.fsm`, and SystemVerilog behavior
remains unchanged and continues to expose per-beat `RRESP` lanes, valid masks,
and length outputs.

The immediate follow-up leaf was `IAL2-FEATURE-COMPLETENESS-FRONTIER.78`,
generated scalar `RRESP` aggregation readiness before behavior changes. That
audit is now complete; the active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.79`, generated scalar behavior first
slice.
