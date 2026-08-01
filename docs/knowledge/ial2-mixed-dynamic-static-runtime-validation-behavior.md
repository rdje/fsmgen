---
id: ial2-mixed-dynamic-static-runtime-validation-behavior
title: IAL2 mixed dynamic/static runtime validation ships for scalar last-beat read-data
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.289 ship?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.289?"
  - "does mixed dynamic/static runtime beat-count validation generate?"
  - "what PPIF sample covers mixed dynamic/static runtime validation?"
  - "does mixed dynamic/static runtime validation remove generated_beat_count_validation residue?"
date: 2026-06-23
status: current
tags: [ial2, axi, manager, dynamic-id, static-id, read-data, burst-length, runtime-validation, behavior]
evidence: docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/REGRESSION_CORPUS.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.289|MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR|read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion|generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse|response_demux_matched_read_beat|beat_count_validation_generated_behavior|generated_beat_count_validation' docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm
  ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.289` ships generated runtime
beat-count/`RLAST` validation over generated mixed dynamic/static read
burst-last response-demux and scalar last-beat read-data.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The sample uses exactly one dynamic read transaction and one concrete static
read transaction, generated mixed dynamic/static `RID && RLAST` response
demux, scalar last-beat `RDATA`/`RRESP` capture, and existing
`burst-length` metadata with `source arlen`, width-8 `axi0_arlen`,
`axlen-plus-one` encoding, request capture, `max-beats 16`, and
`validation runtime-assertion`.

FSMGen emits generated `axi0_arlen`, raw `axi0_r0_arlen_q` and
`axi0_r1_arlen_q` storage, expected-beat storage, read-beat counters,
request-time expected-beat initialization, raw matched-read-beat counter
increments, and four runtime assertions per covered transaction. The dynamic
counter matches raw accepted beats by captured dynamic `RID`; the static
counter matches raw accepted beats by reserved concrete `RID`. Counter
increments are not gated by `RLAST`.

Reports keep `bounded_last_beat_read_data_contract`, the mixed-specific
completion validity string
`generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
`burst_length_validation: runtime_assertion`,
`beat_count_match_source: response_demux_matched_read_beat`, generated
beat-count artifacts, and remove `generated_beat_count_validation` from
read-data residue.

The `.287` report-only sample remains supported without expected-beat
storage, read-beat counters, beat-count rules, or runtime assertions.
Mixed multi-beat output banks, multiple mixed transactions, same-cycle
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future owners.
