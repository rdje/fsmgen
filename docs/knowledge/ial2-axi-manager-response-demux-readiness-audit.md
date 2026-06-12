---
id: ial2-axi-manager-response-demux-readiness-audit
title: AXI response demux needs a write BID public contract before implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.25 conclude?"
  - "can AXI response demux be implemented directly after auto-ID request drive?"
  - "why does response demux need a public contract first?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.26?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.25|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.26|write response-demux public contract|completion names are authored inputs|BID' docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.25` concluded that generated response
demux should not be implemented directly yet.

The current IAL1/IAL0/SystemVerilog substrate can likely carry a bounded write
`BID` demux once the source contract exists: ID-family metadata gives the
response ID signal and width, `.23` gives selected-ID/busy state, and existing
rules/assertions can lower equality checks and release actions.

The blocker is public-contract ambiguity. Existing transaction `completion`
names are authored inputs today, and `write-complete` is an abstract
direction-level completion event, not explicitly a `BVALID && BREADY`
response-channel event. FSMGen must not silently reinterpret those names as
generated demux signals.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.26` owns selection of the bounded AXI write
response-demux public contract before parser/report or generated behavior
changes.
