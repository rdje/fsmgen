---
id: ial2-ppif-valid-ready-bundle-first-slice
title: IAL2 PPIF Valid-Ready bundle first slice
answers:
  - "does .ppif support multiple valid-ready-channel objects now?"
  - "how do I run a multi-channel PPIF bundle?"
  - "where is the runnable PPIF bundle sample?"
  - "does PPIF bundle outdir write HDL?"
  - "does PPIF bundle semantic JSON work?"
  - "what PPIF bundle CLI modes are shipped?"
date: 2026-06-12
status: current
tags: [ial2, ppif, valid-ready, bundle, cli]
evidence: docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md; docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md; ppif/axi_aw_w_valid_ready_bundle.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; bin/fsmgen; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.md; docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t
---

`.ppif` now supports multiple unique `(valid-ready-channel ...)` objects in
one file for the bounded Valid-Ready bundle path. The tracked runnable sample
is `ppif/axi_aw_w_valid_ready_bundle.ppif`.

Run `./bin/fsmgen --emit-schedule-json
ppif/axi_aw_w_valid_ready_bundle.ppif` for the aggregate
`fsmgen.ial2.protocol_intent.valid_ready_bundle.v1` report. Run
`./bin/fsmgen --outdir generated --output bundle.sv
ppif/axi_aw_w_valid_ready_bundle.ppif` to write every generated channel `.isf`
and `.fsm` review artifact, the aggregate wrapper/top `.fsm`, and wrapper/top
SystemVerilog HDL. Run `./bin/fsmgen --strict --check --json
ppif/axi_aw_w_valid_ready_bundle.ppif` for check JSON.

Default HDL generation and `--verify-hdl` now use the selected aggregate
wrapper/top entry for the tracked AW/W bundle sample. Aggregate semantic JSON
works through the bundle semantic JSON slice and reports that selected entry.
The existing single-channel `.ppif` HDL and semantic JSON behavior remains
unchanged.
