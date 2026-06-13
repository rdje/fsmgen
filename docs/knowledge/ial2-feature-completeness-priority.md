---
id: ial2-feature-completeness-priority
title: IAL2 is the current feature-completeness priority on the SV-backed path
answers:
  - "what is the current feature completeness priority?"
  - "should IAL2 be prioritized before VHDL?"
  - "what task owns IAL2 feature completeness?"
  - "what is the next IAL2 PNT frontier?"
  - "can IAL2 feature completion require new IAL1 features?"
date: 2026-06-13
status: current
tags: [ial2, ial1, ial0, systemverilog, roadmap, task-tree, feature-completeness]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER|IAL2 feature completeness|IAL1/IAL0/SV prerequisites|VHDL backend/reroute' docs/TASK_TREE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

The current feature-completeness priority is IAL2 on the
SystemVerilog-backed path.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.58` owns the next PNT frontier:
implement parser/report metadata and static validation for explicit AXI
last-beat read-data capture.

Completed `.47` shipped generated single-beat `RDATA`/`RRESP` capture
behavior. Completed `.48` selected `.49` because the current public read-data
surface is still single-beat and multi-beat read-data reassembly needs a
selected last-beat/completion contract before implementation.
Completed `.49` selected `.50` because no new IAL1/IAL0/SystemVerilog
substrate prerequisite is evident, but direct parser/report metadata or HDL
behavior would be premature without the public burst/`RLAST` contract.
Completed `.50` selected additive read `response-demux` syntax for
`response-scope burst-last`; it keeps transaction completion as the generated
last-beat pulse, publishes no per-transaction beat-valid output, uses `RLAST`
rather than `ARLEN`/beat-count metadata for this first boundary, and leaves
read-data reassembly deferred. Completed `.51` shipped parser/report metadata
and static validation for that contract while keeping generated `.isf`,
`.fsm`, and HDL behavior unchanged. Completed `.52` found no new
IAL1/IAL0/SystemVerilog prerequisite and selected direct generated behavior:
add the generated `RLAST` input, reuse generated `RID` matching, pulse
transaction completions only on matched last beats, and keep read-data
reassembly plus beat-count validation deferred. Completed `.53` shipped that
generated behavior and moved the frontier to a post-`RLAST` selector.
Completed `.54` found stale generated report prose that still calls
burst-last `RLAST` report-only and still says generated burst/last-beat
tracking remains outside the shell; it selected `.55` as the narrow
report/static-text alignment prerequisite before larger AXI feature work.
Completed `.55` aligned that report prose with shipped generated behavior and
advanced the frontier to `.56`, the next public read-data/burst owner
selector. Completed `.56` selected `.57`, public AXI burst read-data contract
selection, because direct behavior still needs an explicit public choice for
capture scope, output binding, beat-count/depth, `RRESP` aggregation,
interleaving policy, diagnostics, and report residue movement. Completed
`.57` selected explicit last-beat read-data capture as the first bounded
burst-side contract and advanced the frontier to `.58`, parser/report
metadata and static validation for that contract.

Selected IAL2 work may include required IAL1 or IAL0/SV support, but only when
those prerequisites are explicit, task-tree owned, documented, and
regression-backed. VHDL backend/reroute work remains deferred until the
SV-backed IAL0/IAL1/IAL2 path is feature complete.
