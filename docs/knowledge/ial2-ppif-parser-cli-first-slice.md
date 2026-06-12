---
id: ial2-ppif-parser-cli-first-slice
title: IAL2 .ppif parser and CLI first slice
answers:
  - "is .ppif supported by the CLI?"
  - "how do I run a .ppif file?"
  - "does .ppif emit generated .isf before .fsm?"
  - "are .pif .ppi .axi supported?"
  - "what PPIF syntax is supported first?"
  - "where is the first runnable .ppif sample?"
date: 2026-06-12
status: current
tags: [ial2, ppif, parser, cli, valid-ready]
evidence: docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; ppif/axi_aw_valid_ready.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; bin/fsmgen; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t
---

`.ppif` is now accepted by `bin/fsmgen` as the first public IAL2 file surface.
The first supported syntax is one top-level
`(protocol-platform-intent NAME ...)` form with `(profile axi4)`, `(source ...)`,
and exactly one `(valid-ready-channel ...)` object.

The CLI path preserves the required lowering chain: `.ppif` parses into the
IAL2 Valid-Ready contract, emits generated `.isf`, lowers that generated `.isf`
through the existing IAL1 scheduler to generated `.fsm`, and then uses the
normal HDL path. `--outdir` materializes both generated review artifacts.
`--emit-schedule-json` emits the IAL2 source-anchor/residue report.

The first runnable checked-in sample is `ppif/axi_aw_valid_ready.ppif`.

Unsupported aliases remain unsupported in this first slice. `.pif`, `.ppi`,
`.axi`, protocol-specific aliases, multiple PPIF objects, and full AXI manager
behavior all require later exact owners.
