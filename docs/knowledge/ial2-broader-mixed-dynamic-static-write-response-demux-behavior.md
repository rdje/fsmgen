---
id: ial2-broader-mixed-dynamic-static-write-response-demux-behavior
title: One dynamic plus three static write response-demux is generated
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.318 ship?"
  - "does AXI IAL2 support one dynamic plus three static write BID demux?"
  - "which sample covers three static mixed dynamic write response demux?"
  - "what is the broader mixed dynamic/static write demux boundary?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, write, response-demux, behavior]
evidence: docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=multi_static3 FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 perl -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.318` ships generated bounded write `BID`
response-demux behavior for one dynamic write transaction plus three concrete
static write transactions.

The public support-accounted sample is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

The generated report reuses
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` and exposes
`dynamic_transactions = [w0]`, `static_transactions = [w1, w2, w3]`, static-ID
reservations for `4'd3`, `4'd5`, and `4'd7`, generated completions/rules for
all four transactions, dynamic static-ID exclusions, request onehot,
response active-match, pairwise unique-match, and completion-active
assertions.

Read-side, read-data, two-dynamic-plus-static, general capped mixed sets,
same-cycle, queue, scoreboard, backend, and VHDL work remain future exact
owners.
