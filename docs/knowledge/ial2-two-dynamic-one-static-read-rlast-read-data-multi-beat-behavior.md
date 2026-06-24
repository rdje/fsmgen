---
id: ial2-two-dynamic-one-static-read-rlast-read-data-multi-beat-behavior
title: Two-dynamic/one-static mixed read RLAST read-data multi-beat output banks shipped
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.357 ship?"
  - "does two-dynamic-plus-static mixed read RLAST read-data support multi-beat output banks?"
  - "which sample covers two-dynamic-plus-static mixed read RLAST read-data multi-beat output banks?"
  - "what remains after two-dynamic-plus-static mixed read-data multi-beat output banks?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, read-data, read-response-demux, rlast, burst-length, runtime-validation, multi-beat, output-bank, behavior]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md; ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; t/248-regression-corpus-accounting.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.357|IAL2-FEATURE-COMPLETENESS-FRONTIER\.358|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR|multi_dynamic_burst_last_read_data_multi_beat|mixed_dynamic_static_read_data_multi_dynamic_multi_beat|bounded_multi_beat_read_data_contract|multi_beat_reassembly_generated_behavior|status_aggregation_generated_behavior|same_id_ordering' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_MULTI_BEAT_BEHAVIOR.md ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm perl/FSM/Support/RegressionCorpus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t t/248-regression-corpus-accounting.t docs/REGRESSION_CORPUS.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.357` ships generated multi-beat output
banks over generated two-dynamic-plus-one-static mixed dynamic/static
runtime-validation read-data.

The shipped public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif
```

It keeps the `r0`/`r1` dynamic and static `r2` transaction set, generated
mixed `RID && RLAST` completion pulses, runtime `ARLEN + 1` beat-count
validation, and four beat-count/`RLAST` assertions per transaction. It adds
per-transaction RDATA/RRESP lane outputs, valid masks, read-length outputs,
and worst-observed scalar `RRESP` aggregate outputs for `r0`, `r1`, and `r2`.

The focused support identity is
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat`,
the coverage key is
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli`,
and the focused t/1438 behavior label is
`mixed_dynamic_static_read_data_multi_dynamic_multi_beat`.

The exact boundary is still narrow: single-beat read-data over `.344`,
broader mixed dynamic/static cardinalities, same-cycle request widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, aliases, queued/blocking policy,
and full-manager behavior remain later exact owners.
