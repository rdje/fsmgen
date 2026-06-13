---
id: ial2-axi-manager-read-data-metadata-first-slice
title: AXI read-data metadata reports structural RDATA and RRESP bindings
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.45 ship?"
  - "is AXI read-data metadata supported?"
  - "what does the read_data report contain?"
  - "does read-data generate RDATA capture yet?"
  - "what is ppif/axi_manager_capacity_status_read_data.ppif?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-data, rdata, rresp, ppif, report, metadata, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md; ppif/axi_manager_capacity_status_read_data.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'read_data|read-data|generated_read_data_capture|axi_manager_capacity_status_read_data|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.45' docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md ppif/axi_manager_capacity_status_read_data.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.45` shipped parser/report metadata and
static validation for the bounded single-beat AXI read-data payload/status
contract.

The public `.ppif` surface now accepts one optional `read-data` clause under
`manager-capacity-status`:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))))
```

The generator reports structural `read_data` metadata with
`generated_behavior: false`. The report names the `RDATA` signal and width,
the 2-bit `RRESP` signal, the generated read response-demux completion pulse
as validity source, and transaction-bound data/status output names.

The checked-in runnable sample is:

```text
ppif/axi_manager_capacity_status_read_data.ppif
```

Generated `RDATA`/`RRESP` capture is not shipped yet. The `.45` tests prove
the generated `.isf`, `.fsm`, and HDL behavior remains unchanged from the read
response-demux sample. `read_data.residue` includes
`generated_read_data_capture`, `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.

The next leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.46`, a readiness audit
for generated single-beat read-data capture behavior.
