---
id: ial2-axi-manager-last-beat-read-data-metadata-first-slice
title: AXI last-beat read-data metadata is parsed and reported without generated capture
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.58 ship?"
  - "is AXI last-beat read-data metadata supported?"
  - "what is ppif/axi_manager_capacity_status_read_data_last_beat.ppif?"
  - "does AXI last-beat RDATA capture generate behavior yet?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.58?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.59?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, burst, rlast, last-beat, metadata, ppif, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_last_beat.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.58|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.59|axi_manager_capacity_status_read_data_last_beat|bounded_last_beat_read_data_contract|generated_read_response_demux_last_beat_completion_pulse|generated_last_beat_read_data_capture' docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md ppif/axi_manager_capacity_status_read_data_last_beat.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.58` shipped parser/report metadata and
static validation for explicit AXI last-beat read-data capture.

The public `.ppif` surface now accepts this `read-data` shape only when paired
with generated read response-demux metadata using `response_scope burst_last`:

```text
(capture-scope last-beat)
(completion-source response-demux)
(status-policy last-beat)
(interleaving last-beat-by-rid)
```

The report mode is `bounded_last_beat_read_data_contract` with
`generated_behavior: false`. It reports
`completion_validity: generated_read_response_demux_last_beat_completion_pulse`,
`status_aggregation: none`, `burst_length_source: rlast_only`, no beat
storage, no valid output, no length output, and residue including
`generated_last_beat_read_data_capture`.

The checked-in runnable sample is:

```text
ppif/axi_manager_capacity_status_read_data_last_beat.ppif
```

Generated last-beat `RDATA`/`RRESP` capture behavior is not shipped yet.
Generated `.isf`, `.fsm`, HDL behavior, check JSON semantics, and existing
single-beat read-data behavior remain unchanged. The active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.59`, a readiness audit for generated
last-beat read-data capture behavior.
