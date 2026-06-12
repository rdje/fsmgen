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
  - "does the capability manifest advertise .ppif?"
  - "does the capability manifest list .ppif CLI modes?"
  - "does .ppif check JSON keep the .ppif source path?"
  - "does .ppif semantic JSON keep the .ppif source path?"
  - "does .ppif report the top-level protocol-platform-intent name?"
date: 2026-06-12
status: current
tags: [ial2, ppif, parser, cli, valid-ready]
evidence: docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; ppif/axi_aw_valid_ready.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/LanguageSurfaceContract.pm; bin/fsmgen; t/1436-ial2-ppif-parser-cli.t; t/297-capability-manifest.t; t/317-language-surface-contract.t; t/301-check-json-supported-corpus.t; t/303-normalized-semantic-json-supported-corpus.t; docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md; docs/tasks/LANGUAGE-SURFACE-FILE-CLI-MODES.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t
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
The capability manifest advertises `.ppif` under
`language_surface.file_surfaces`, where it is marked as IAL2 and documented as
lowering through generated `.isf` before generated `.fsm`. The same `.ppif`
file-surface entry publishes `supported_cli_modes[]`, including
`--emit-schedule-json`, `--check --json / --check-json`, and
`--emit-semantic-json`.
Run `./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif` for the
IAL2 source-anchor/residue report, `./bin/fsmgen --outdir generated
ppif/axi_aw_valid_ready.ppif` for review artifacts plus HDL,
`./bin/fsmgen --strict --check --json ppif/axi_aw_valid_ready.ppif` for check
JSON, and `./bin/fsmgen --strict --emit-semantic-json
ppif/axi_aw_valid_ready.ppif` for normalized semantic JSON. The IAL2
source-anchor/residue report preserves the authored top-level
`protocol-platform-intent` name as `source_object.intent_name`.
Successful `.ppif` check JSON and normalized semantic JSON keep
`source.resolved_path` on the resolved `.ppif` input and match the PPIF sample
support-accounting entry. The normalized semantic payload still describes the
generated `.fsm` semantic root.

Unsupported aliases remain unsupported. `.pif`, `.ppi`, `.axi`,
protocol-specific aliases, platform placement clauses, and full AXI manager
behavior all require later exact owners. A later bounded bundle slice now
supports multiple unique `valid-ready-channel` objects for aggregate IAL2
reports, generated review artifacts, check JSON, and aggregate semantic JSON;
default bundle HDL generation remains fail-closed.
