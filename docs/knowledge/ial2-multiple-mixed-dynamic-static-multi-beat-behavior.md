---
id: ial2-multiple-mixed-dynamic-static-multi-beat-behavior
title: Multiple mixed dynamic/static multi-beat output banks ship
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.314 ship?"
  - "does multiple mixed dynamic/static multi-beat read-data work?"
  - "which sample covers multiple mixed dynamic/static multi-beat output banks?"
  - "how many lanes does the multiple mixed dynamic/static multi-beat sample emit?"
  - "what comes after multiple mixed dynamic/static multi-beat output banks?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, multi-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=multi_static_burst_last_read_data_multi_beat FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 perl -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.314|MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR|multi_static_burst_last_read_data_multi_beat|generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|bounded_multi_beat_read_data_contract' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.314` ships generated multiple mixed
dynamic/static multi-beat read-data output banks over generated multiple mixed
dynamic/static runtime beat-count/`RLAST` validation.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif
```

The sample covers `r0`, `r1`, and `r2`, emits 48 `RDATA` lane outputs, 48
`RRESP` lane outputs, three valid masks, three length outputs, three scalar
worst-observed `RRESP` aggregates, and twelve beat-count/`RLAST` runtime
assertions. Read-data residue is empty, and response-demux residue is limited
to `same_id_ordering`.

`.314` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.315`, the next exact-owner
selector after multiple mixed dynamic/static read-data reached multi-beat
output banks.
