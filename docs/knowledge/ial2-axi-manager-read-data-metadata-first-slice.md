---
id: ial2-axi-manager-read-data-metadata-first-slice
title: AXI read-data metadata reports structural RDATA and RRESP bindings
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.45 ship?"
  - "is AXI read-data metadata supported?"
  - "what does the read_data report contain?"
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

At the `.45` metadata boundary, the generator reported structural
`read_data` metadata with `generated_behavior: false`. The report named the
`RDATA` signal and width, the 2-bit `RRESP` signal, the generated read
response-demux completion pulse as validity source, and transaction-bound
data/status output names.

The checked-in runnable sample is:

```text
ppif/axi_manager_capacity_status_read_data.ppif
```

Generated `RDATA`/`RRESP` capture was not shipped in `.45`. The `.45` tests
proved the generated `.isf`, `.fsm`, and HDL behavior remained unchanged from
the read response-demux sample. At that boundary, `read_data.residue` included
`generated_read_data_capture`, `rlast_completion`, `bursts`, and
`multi_beat_read_data_reassembly`.

Generated capture is now shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.47`;
see `docs/knowledge/ial2-axi-manager-read-data-behavior-first-slice.md` for
the current behavior contract.
