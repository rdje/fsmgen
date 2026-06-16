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
date: 2026-06-16
status: current
tags: [ial2, ppif, parser, cli, valid-ready]
evidence: docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; ppif/axi_aw_valid_ready.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/LanguageSurfaceContract.pm; bin/fsmgen; t/1436-ial2-ppif-parser-cli.t; t/297-capability-manifest.t; t/317-language-surface-contract.t; t/301-check-json-supported-corpus.t; t/303-normalized-semantic-json-supported-corpus.t; docs/tasks/IAL2-PPIF-PARSER-CLI-FIRST-SLICE.md; docs/tasks/LANGUAGE-SURFACE-FILE-CLI-MODES.md
reverify: prove -Iperl t/1436-ial2-ppif-parser-cli.t t/1435-axi-ial2-valid-ready-generator.t t/297-capability-manifest.t t/317-language-surface-contract.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t
---

`.ppif` is accepted by `bin/fsmgen` as the first public IAL2 file surface.
The original first supported syntax was one top-level
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
file-surface entry publishes current bounded-public status,
`supported_cli_modes[]`, and the per-suffix boundary text, including
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
protocol-specific aliases, platform placement clauses, full AXI manager
behavior, direct backend lowering, and VHDL all require later exact owners.
Later bounded slices support multiple unique `valid-ready-channel` objects and
one-object AXI manager capacity/status sources. Support-accounted AXI manager
coverage now includes generated auto-ID write/read response-demux,
single-beat, last-beat, and multi-beat read-data capture,
burst-length/runtime validation, scalar `RRESP` aggregation, one-or-more read
burst-last queue-head groups, one-or-more write queue-head groups, and read
single-beat queue-head response-demux including multiple response-demux-only
and scalar read-data groups. Deeper concrete same-ID queue-head groups,
same-family mixed auto-ID plus concrete queue-head demux, direct backend
lowering, and VHDL remain deferred.
