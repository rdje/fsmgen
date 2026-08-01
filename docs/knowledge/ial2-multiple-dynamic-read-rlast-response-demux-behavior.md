---
id: ial2-multiple-dynamic-read-rlast-response-demux-behavior
title: Multiple dynamic read RLAST demux behavior is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.255 ship?"
  - "is multiple dynamic read RLAST response demux generated?"
  - "what is bounded_multi_dynamic_read_rid_rlast_demux_contract?"
  - "what PPIF sample covers multiple dynamic read RLAST demux?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, rlast, generated-behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.255|MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR|axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last|bounded_multi_dynamic_read_rid_rlast_demux_contract|generated bounded multiple all-dynamic read burst-last RID/RLAST response demux|read_data\\.read dynamic coverage requires exactly one dynamic read transaction' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.255` ships generated bounded multiple
dynamic read burst-last/`RLAST` response-demux.

The public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.
It reports `bounded_multi_dynamic_read_rid_rlast_demux_contract`, captures
admitted `ARID` into per-transaction dynamic ID state, uses onehot0 same-cycle
dynamic read requests, keeps active dynamic IDs pairwise unique, completes each
transaction on final `RID && RLAST`, and keeps raw `RID` beat active/unique
assertions unqualified by `RLAST`.

Read-data, burst-length/runtime validation, and multi-beat output banks over
multiple dynamic read demux remain future exact owners.
