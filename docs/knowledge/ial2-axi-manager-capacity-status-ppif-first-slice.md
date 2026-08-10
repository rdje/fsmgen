---
id: ial2-axi-manager-capacity-status-ppif-first-slice
title: AXI manager capacity/status PPIF shipped
answers:
  - "is public .ppif AXI manager capacity/status shipped?"
  - "how do I run the AXI manager capacity/status .ppif sample?"
  - "what does ppif/axi_manager_capacity_status.ppif generate?"
  - "does AXI manager capacity/status .ppif preserve public source identity?"
  - "what remains out of scope after the capacity/status PPIF first slice?"
  - "where is the AXI manager capacity status family documented?"
  - "how many AXI PPIF sources are shipped?"
  - "how many AXI manager capacity status PPIF sources are shipped?"
date: 2026-08-10
status: current
tags: [ial2, ppif, axi, manager, capacity, status, cli]
evidence: docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md; docs/book/src/16aa-ial2-axi-manager-capacity-status.md; ppif/axi_manager_capacity_status.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md
reverify: ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status.ppif
---

Public AXI manager capacity/status accepts one `(manager-capacity-status NAME
...)` object under a `(protocol-platform-intent ...)` root with `(profile
axi4)` and top-level source anchors. Its base sample is
`ppif/axi_manager_capacity_status.ppif`.

The shipped AXI corpus contains 153 `.ppif` sources: 140
`axi_manager_capacity_status*.ppif` sources documented in chapter 16aa, plus
13 monitor/initiator sources documented in chapter 16a. Within the 140-source
family, overlapping clause counts are: 139 ID, 138 transaction, 17 automatic
ID lifecycle, 78 same-ID ordering, 130 response demultiplexing, 79 read-data,
and 48 burst-length sources.

The CLI supports schedule/check/semantic JSON, `--outdir`, HDL, and HDL
verification. The adapter maps to
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, emits `.isf` before
`.fsm`, then generates SystemVerilog.

Support accounting calls it `intent.ppif_axi_manager_capacity_status`;
check/semantic JSON preserve `source.resolved_path`. The base selects no ID,
ordering, demux, or burst behavior; named combinations do.
Mixed objects, multiple managers, blocking, aliases, general scoreboarding,
full-manager behavior, and VHDL stay outside its contract.
