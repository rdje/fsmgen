---
id: ial2-two-dynamic-one-static-read-single-beat-read-data-behavior
title: Two-dynamic/one-static mixed read single-beat read-data behavior ships
answers:
  - "does two-dynamic-plus-static mixed read single-beat read-data work?"
  - "which PPIF sample covers two-dynamic-plus-static mixed read single-beat read-data?"
  - "what completion validity does two-dynamic-plus-static single-beat read-data report?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.361 ship?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, single-beat, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; perl/FSM/Support/RegressionCorpus.pm; t/248-regression-corpus-accounting.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: >-
  scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 4096 -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.361|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR|axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data|mixed_dynamic_static_read_data_multi_dynamic|generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse|bounded_single_beat_read_data_contract' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md
  docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.361` ships scalar single-beat
`RDATA`/`RRESP` capture over the `.344` generated
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
```

It keeps dynamic transactions `r0` and `r1`, concrete static transaction `r2`
with ID `3`, response-demux completion source
`generated_multi_mixed_dynamic_static_read_demux`, read-data mode
`bounded_single_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
generated inputs `axi0_rdata`/`axi0_rresp`, scalar outputs for `r0`/`r1`/`r2`,
and generated capture rules `axi0_r0_read_data_capture`,
`axi0_r1_read_data_capture`, and `axi0_r2_read_data_capture`.

The slice intentionally leaves `RLAST`, raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinalities, queues, scoreboards,
backend variants, VHDL, and full-manager behavior to separate exact owners.
