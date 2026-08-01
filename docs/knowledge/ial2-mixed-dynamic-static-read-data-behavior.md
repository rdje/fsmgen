---
id: ial2-mixed-dynamic-static-read-data-behavior
title: IAL2 mixed dynamic/static read-data behavior ships scalar capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.284 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.284?"
  - "does mixed dynamic/static read-data capture work?"
  - "does read-data over mixed dynamic/static read demux work?"
  - "what PPIF samples cover shipped mixed dynamic/static read-data?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.284|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.285|MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data|generated_mixed_dynamic_static_read_response_demux_completion_pulse|generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|mixed dynamic/static read-data capture' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
  ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.284` shipped generated bounded scalar
read-data capture over generated mixed dynamic/static read response-demux.

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif
```

The single-beat sample composes generated mixed dynamic/static read
single-beat `RID` demux with scalar `capture-scope single-beat` read-data.
The last-beat sample composes generated mixed dynamic/static read burst-last
`RID && RLAST` demux with scalar `capture-scope last-beat` read-data.

Read-data coverage is intentionally bounded to exactly one dynamic read
transaction followed by one concrete static read transaction. The generator
maps each transaction to its generated mixed demux completion pulse, emits
shared `axi0_rdata`/`axi0_rresp` inputs, scalar data/status outputs, and one
capture rule per transaction.

Reports keep `bounded_single_beat_read_data_contract` or
`bounded_last_beat_read_data_contract`, list `r0,r1` transaction coverage, and
use the mixed-specific completion validity strings
`generated_mixed_dynamic_static_read_response_demux_completion_pulse` and
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.

Burst-length/runtime validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.
