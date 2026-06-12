---
id: ial2-ppif-bundle-hdl-entry-first-slice
title: IAL2 PPIF bundle HDL entry first slice
answers:
  - "does PPIF bundle default HDL generation work?"
  - "does PPIF bundle verify-hdl work?"
  - "what HDL entry does PPIF bundle generation use?"
  - "what PPIF bundle review artifacts does outdir write now?"
  - "does PPIF bundle HDL emit sampled-value helper wires?"
date: 2026-06-12
status: current
tags: [ial2, ppif, bundle, hdl, verify-hdl]
evidence: docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm; perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t
---

Multi-channel `.ppif` Valid-Ready bundles now have a bounded selected HDL
entry for the tracked AW/W sample. Default SystemVerilog generation and
`--verify-hdl` use the generated aggregate wrapper/top `.fsm`
`axi_aw_w_valid_ready_bundle.fsm`, not either generated channel `.fsm`.

`--outdir` writes both generated channel `.isf` files, both generated channel
`.fsm` files, and the aggregate wrapper/top `.fsm`. The emitted HDL contains
the AW and W generated monitor modules plus the `axi_aw_w_valid_ready_bundle`
wrapper module.

Sampled-value expressions such as `$past(awvalid)` remain inline in assertion
property text. Sampled-value helper chains are pruned from the general
combinational intermediate-signal set, so generated HDL does not emit
unclocked `assign functioncall_expr = $past(...)` helper wires.
