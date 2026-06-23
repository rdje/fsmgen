---
id: ial2-three-static-mixed-dynamic-static-read-rlast-response-demux-behavior
title: Three-static mixed read RLAST demux behavior ships
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.326 ship?"
  - "does AXI IAL2 support one dynamic plus three static read RLAST demux?"
  - "is three-static mixed dynamic/static read RLAST demux implemented?"
  - "which sample covers three-static mixed read RLAST response demux?"
  - "what is the three-static mixed read RLAST boundary?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read, rlast, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_rlast_demux_multi_static3 FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.326` ships generated bounded one-dynamic
plus three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux behavior.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

The generated contract uses existing `response-demux.read` syntax with
`response-scope burst-last`, one-bit `last-signal`, and generated
transaction completion. It reports
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
`dynamic_transactions = [r0]`, `static_transactions = [r1, r2, r3]`, static
ID reservations/exclusions for `4'd3`, `4'd5`, and `4'd7`, raw `RID`
active/unique assertions, and final `RID && RLAST` completion pulses for all
four transactions.

Read-data, raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, queues/scoreboards, direct backend, backend-language
variants, and VHDL remain future owners.
