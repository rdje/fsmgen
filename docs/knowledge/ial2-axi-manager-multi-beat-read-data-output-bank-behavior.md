---
id: ial2-axi-manager-multi-beat-read-data-output-bank-behavior
title: AXI multi-beat read-data output-bank behavior now generates payload lanes
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.74 ship?"
  - "does AXI multi-beat read-data generate RDATA and RRESP outputs now?"
  - "does the multi-beat read-data sample emit per-beat outputs?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.75?"
date: 2026-08-10
status: current
tags: [ial2, axi, manager, read-data, multi-beat, output-bank, rdata, rresp, behavior, hdl, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md; docs/book/src/16aa-ial2-axi-manager-capacity-status.md; ppif/axi_manager_capacity_status_read_data_multi_beat.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md
reverify: ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.74` ships generated AXI multi-beat
read-data output-bank behavior for the public multi-beat sample.

The generated IAL1/FSM/SystemVerilog path now emits `axi0_rdata` and
`axi0_rresp` payload inputs, per-transaction data/status lane outputs,
valid-mask outputs, length outputs, request-time output-bank clear rules, and
one lane capture rule per beat. Lane capture guards combine the generated
response-demux matched-read-beat expression, `!request_event`, and current
beat-count equality.

Schedule JSON reports `multi_beat_reassembly_generated_behavior: true`,
generated payload inputs, generated output-bank outputs, output-init rules,
per-lane capture rules, generated worst-observed `RRESP` aggregation, and empty
`read_data`/`response_demux` residue for this exact source.

The mdBook reference documents the bounded bank, validation, interleaving, and
residue boundary; its empty result is not a claim of arbitrary reassembly.
