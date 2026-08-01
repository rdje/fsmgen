---
id: ial2-mixed-dynamic-static-read-data-burst-length-behavior
title: IAL2 mixed dynamic/static read-data burst-length behavior ships report-only ARLEN capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.287 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.287?"
  - "does mixed dynamic/static read-data burst-length capture work?"
  - "does report-only ARLEN capture work over mixed dynamic/static read-data?"
  - "what PPIF sample covers mixed dynamic/static read-data burst-length?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, burst-length, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.287|MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length|generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|mixed dynamic/static read-data burst-length|burst_length_generated_behavior' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_BURST_LENGTH_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif
  t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.287` ships generated report-only
raw-`ARLEN` burst-length capture over generated mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif
```

The sample uses exactly one dynamic read transaction and one concrete static
read transaction, generated mixed dynamic/static `RID && RLAST` response
demux, scalar last-beat `RDATA`/`RRESP` capture, and existing
`burst-length` metadata with `source arlen`, width-8 `axi0_arlen`,
`axlen-plus-one` encoding, request capture, `max-beats 16`, and
`validation report-only`.

FSMGen emits generated `axi0_arlen` input, raw `axi0_r0_arlen_q` and
`axi0_r1_arlen_q` storage, and request-guarded
`axi0_r0_burst_length_capture` / `axi0_r1_burst_length_capture` rules.
Scalar data/status capture remains guarded by the generated mixed
`RID && RLAST` completion pulses.

Reports keep `bounded_last_beat_read_data_contract`, the mixed-specific
completion validity string
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
`burst_length_generated_behavior: true`, and
`burst_length_validation: report_only`.

Runtime beat-count/`RLAST` validation, multi-beat output banks, multiple mixed
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.
