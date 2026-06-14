---
id: ial2-axi-manager-multi-beat-read-data-metadata-first-slice
title: AXI multi-beat read-data metadata accepts output-bank syntax without payload generation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.72 ship?"
  - "is capture-scope multi-beat accepted in PPIF?"
  - "does the AXI multi-beat read-data sample generate per-beat outputs yet?"
  - "what is ppif/axi_manager_capacity_status_read_data_multi_beat.ppif?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.72?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, ppif, metadata, validation, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.72` ships parser/report metadata and
static validation for public AXI multi-beat read-data output-bank syntax.

The public sample is
`ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`. It uses
`capture-scope multi-beat`, `status-policy per-beat`,
`interleaving multi-beat-by-rid`, mandatory ARLEN `burst-length`, and
`validation runtime-assertion`. Per transaction it binds a data output prefix,
status output prefix, valid-mask output, and length output.

The report mode is `bounded_multi_beat_read_data_contract`.
Schedule JSON reports generated lane names, valid-mask widths, length-output
widths, `beat_match_source: response_demux_matched_read_beat`,
`output_shape: per_beat_output_bank`, and
`multi_beat_reassembly_generated_behavior: false`.

Generated artifacts remain limited to existing response-demux, ARLEN capture,
and beat-count/`RLAST` runtime-validation behavior. The slice does not emit
generated `RDATA`/`RRESP` payload inputs, per-beat data/status outputs,
valid masks, length outputs, or multi-beat payload capture/reassembly rules.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.73`, a readiness
audit before generated multi-beat read-data reassembly/output behavior.
