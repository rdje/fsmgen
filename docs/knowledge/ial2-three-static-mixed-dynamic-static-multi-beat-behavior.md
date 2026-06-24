---
id: ial2-three-static-mixed-dynamic-static-multi-beat-behavior
title: Three-static mixed read-data multi-beat output banks ship
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.337 ship?"
  - "does three-static mixed dynamic/static multi-beat read-data work?"
  - "which PPIF sample covers three-static mixed dynamic/static multi-beat output banks?"
  - "how many lanes does the three-static mixed multi-beat sample emit?"
  - "what remains after three-static mixed multi-beat output banks?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, burst-length, runtime-validation, multi-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: env FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_data_multi_static3_multi_beat FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.337` ships generated multi-beat
read-data output banks over generated one-dynamic plus three-concrete-static
mixed dynamic/static runtime-validation read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif
```

The generated behavior covers ordered transactions `r0`, `r1`, `r2`, and
`r3`; emits 64 `RDATA` lane outputs and 64 `RRESP` lane outputs, 16 of each
per transaction; adds valid-mask, length, scalar worst-observed `RRESP`,
raw-`ARLEN`, expected-beat, and read-beat-count state for each transaction;
and reports read-data residue as empty while response-demux residue remains
limited to `same_id_ordering`.

Two-dynamic-plus-static shapes, broader mixed cardinalities, same-cycle
widening, queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact-owner work.
