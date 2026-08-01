---
id: ial2-multiple-dynamic-read-data-behavior
title: IAL2 multiple dynamic read-data behavior ships scalar capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.259 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.259?"
  - "what is multiple dynamic read-data behavior?"
  - "does read-data over multiple dynamic read demux work?"
  - "what PPIF samples cover shipped multiple dynamic read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif; ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.259|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.260|MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR|axi_manager_capacity_status_dynamic_read_data_multi|dynamic read_data consumption is supported for one-or-more generated all-dynamic read transactions|bounded_single_beat_read_data_contract|bounded_last_beat_read_data_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif t/1436-ial2-ppif-parser-cli.t
  t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.259` shipped generated bounded scalar
read-data capture over generated all-dynamic multiple read response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif
```

The single-beat sample composes generated multiple dynamic read single-beat
`RID` demux with scalar `capture-scope single-beat` read-data. The last-beat
sample composes generated multiple dynamic read burst-last `RID && RLAST`
demux with scalar `capture-scope last-beat` read-data.

Read-data bindings must cover every generated dynamic read demux transaction
exactly once. The generator maps each covered transaction to that
transaction's generated completion pulse and emits scalar data/status outputs
plus one capture rule per transaction. Reports keep the scalar modes
`bounded_single_beat_read_data_contract` and
`bounded_last_beat_read_data_contract` while listing multiple transaction
entries.

Burst-length/runtime validation and multi-beat output banks over multiple
dynamic read demux remain later exact owners, as do mixed dynamic/static demux,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL.
