---
id: ial2-ppif-multi-valid-ready-readiness
title: IAL2 PPIF multi Valid-Ready readiness boundary
answers:
  - "can .ppif contain multiple valid-ready-channel objects?"
  - "why is multi-channel .ppif not just a parser change?"
  - "what blocks AXI five-channel PPIF support?"
  - "what must happen before .ppif accepts multiple Valid-Ready channels?"
  - "does .ppif support AXI AW W B AR R channels in one file?"
date: 2026-06-12
status: current
tags: [ial2, ppif, valid-ready, readiness, axi]
evidence: docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md; docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm; bin/fsmgen; perl/FSM/Adapter/ISF/Parser.pm; docs/ISF_SPEC.md; docs/tasks/IAL2-PPIF-MULTI-VALID-READY-READINESS.md
reverify: rg -n "supports exactly one|generate expects exactly one|generated_ial1|generated_ial0|multiple top-level|Multi-channel" docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm bin/fsmgen perl/FSM/Adapter/ISF/Parser.pm docs/ISF_SPEC.md
---

`.ppif` does not currently support multiple `(valid-ready-channel ...)`
objects in one file. The first public `.ppif` slice intentionally accepts one
Valid-Ready object and rejects a duplicate channel object before generation.

Multi-channel `.ppif` support is not just a parser relaxation. The PPIF
adapter has a singular source/channel contract, the Valid-Ready generator
returns one generated `.isf` artifact and one IAL2 report, the CLI path selects
one generated `.fsm` artifact as the HDL input, and the ISF parser accepts one
top-level `(actor ...)` compile/report entry actor. A five-channel AXI-shaped
file also needs a source-anchor attribution model for intent-level versus
channel-level evidence.

A future behavior owner must first choose an aggregate result/report/source
artifact contract, an ISF wrapper/top actor contract, or continued
one-object-per-file composition. Until that owner lands, AXI AW/W/B/AR/R
channel bundles in a single `.ppif` file remain unshipped and fail closed.
