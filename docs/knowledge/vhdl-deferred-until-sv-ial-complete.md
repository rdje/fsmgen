---
id: vhdl-deferred-until-sv-ial-complete
title: VHDL backend work is deferred until the SV-backed IAL path is feature complete
answers:
  - "should VHDL backend work happen before SV backend feature completeness?"
  - "when should direct VHDL rerouting resume?"
  - "is R11-DIRECT-STRUCTURAL-VHDL-REROUTING PNT-ready?"
  - "is VHDL deferred until IAL0 IAL1 IAL2 are feature complete?"
date: 2026-06-12
status: current
tags: [vhdl, systemverilog, ial0, ial1, ial2, roadmap, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/decisions/0001-isf-abstraction-layering.md; docs/knowledge/axi-ial2-valid-ready-generator-first-slice.md; docs/knowledge/ial2-ppif-parser-cli-first-slice.md; docs/knowledge/ial2-ppif-bundle-hdl-entry-first-slice.md
reverify: rg -n 'R11-DIRECT-STRUCTURAL-VHDL-REROUTING|IAL2-FEATURE-COMPLETENESS-FRONTIER|IAL0/IAL1/IAL2|SystemVerilog-backed|VHDL backend/reroute' docs/TASK_TREE.md docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

Direct VHDL backend/reroute work is intentionally deferred until the
SystemVerilog-backed IAL0, IAL1, and IAL2 path is feature complete.

`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` records the selector outcome: do not
select or implement a direct VHDL `StructuralRTLIR` reroute target while the
primary SV-backed language/protocol-intent path is still incomplete. Future
VHDL work must first re-check IAL feature-completeness, direct structural
readiness, and VHDL validation availability before opening a selector or
implementation leaf.

The active near-term priority is `IAL2-FEATURE-COMPLETENESS-FRONTIER.1`, which
must audit the shipped IAL2 surface and select the next exact
feature-completeness slice on the SV-backed path. That IAL2 slice may include
explicitly selected IAL1 or IAL0/SV prerequisites when needed for clean
lowering.
