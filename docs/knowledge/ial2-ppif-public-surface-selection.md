---
id: ial2-ppif-public-surface-selection
title: IAL2 .ppif public surface selection
answers:
  - "which extension is the first public IAL2 file surface?"
  - "is .ppif selected for IAL2?"
  - "are .pif or .ppi accepted IAL2 suffixes?"
  - "is .axi the first IAL2 public suffix?"
  - "what should the first .ppif syntax look like?"
date: 2026-06-12
status: current
tags: [ial2, ppif, public-surface, parser, cli]
evidence: docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/tasks/IAL2-PUBLIC-PPIF-SURFACE-SELECTION.md; docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md
reverify: rg -n "\\.ppif|protocol-platform-intent|valid-ready-channel" docs/decisions/0016-ppif-is-first-public-ial2-container.md docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md docs/book/src/14-feature-backlog.md
---

Decision `0016` selects `.ppif` as the first public generic IAL2 file
extension. It stands for Protocol/Platform Intent Format. `.pif` and `.ppi`
remain historical candidates, not first implementation suffixes. `.axi` and
other protocol-specific suffixes remain possible future profile aliases over
the same IAL2 layer, but they are not the first public suffix.

The first `.ppif` source shape is Lispish with top-level
`(protocol-platform-intent NAME ...)`, a `(profile axi4)` clause, source
anchors, and one `(valid-ready-channel ...)` object that maps to the existing
in-process AXI Valid-Ready generator. Parser and CLI support for that one
object shape is now shipped by `IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1`.
