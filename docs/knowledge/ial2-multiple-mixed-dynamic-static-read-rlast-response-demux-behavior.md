---
id: ial2-multiple-mixed-dynamic-static-read-rlast-response-demux-behavior
title: Multiple mixed dynamic/static read RLAST demux behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.303 ship?"
  - "does multiple mixed dynamic/static read burst-last response-demux generate behavior?"
  - "which PPIF sample covers multiple mixed dynamic/static read RLAST demux?"
  - "what is bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.303|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR|read_mixed_dynamic_static_response_demux_multi_static_burst_last|bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract|generated_multi_mixed_dynamic_static_read_demux_last_beat|mixed_dynamic_static_read_rlast_demux_multi_static' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.303` ships generated bounded multiple
mixed dynamic/static read burst-last `RID && RLAST` response-demux behavior.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The generated contract covers exactly one dynamic read transaction plus two
pairwise-distinct concrete static read transactions. It reports mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped `mixed_transactions` and `static_id_reservations`, dynamic capture
exclusions for `4'd3` and `4'd5`, raw `RID` active/unique assertions, and
final `RID && RLAST` completion pulses for `r0`, `r1`, and `r2`.

Read-data, raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, queues/scoreboards, direct backend, backend-language
variants, and VHDL remain future owners.
