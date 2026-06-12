---
id: ial2-axi-manager-post-response-demux-residue-alignment-selection
title: Post response-demux selector chose auto-ID lifecycle residue alignment
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.31 select?"
  - "why is auto_id_lifecycle.residue the next IAL2 slice?"
  - "what comes immediately after generated AXI write BID response demux?"
  - "is same-ID ordering next after response demux?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, auto-id, residue, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.31|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.32|auto_id_lifecycle\\.residue|response_demux|residue alignment' docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.31` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.32` as the next exact IAL2 slice.

The post-`.30` report correctly sets `response_demux.generated_behavior: true`
and removes `response_demux` from `id_response_rule_engine.residue`, but it
still lists `response_demux` under `auto_id_lifecycle.residue`. That residue
was correct before generated demux completions existed. It is stale now because
generated write demux completion pulses drive auto-ID release.

`.32` is a narrow report-contract cleanup: remove `response_demux` from
`auto_id_lifecycle.residue` when explicit generated write response demux is
present, while proving generated `.isf`, `.fsm`, and SystemVerilog behavior do
not change.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.32` has now shipped that selected cleanup.
See `docs/knowledge/ial2-axi-manager-auto-id-residue-alignment-first-slice.md`.

Same-ID ordering, read `RID` demux, read-data interleaving/reassembly, bursts,
queued/blocking policy, profile aliases, full-manager syntax, and VHDL remain
future exact-owner work after this cleanup.
