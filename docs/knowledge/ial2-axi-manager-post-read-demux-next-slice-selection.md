---
id: ial2-axi-manager-post-read-demux-next-slice-selection
title: Post-read-demux next slice is read-data and burst readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.42 select?"
  - "what comes after generated read response demux?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.43?"
  - "what is the next AXI manager IAL2 audit?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-data, bursts, rlast, interleaving, per-id, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.42|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.43|POST_READ_DEMUX_NEXT_SLICE_SELECTION|read-data payload|burst/`RLAST`|per-ID ordering/reassembly' docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.42` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.43` as the next readiness audit after
generated read response demux.

The audit covers AXI read-data payload, burst/`RLAST`, and per-ID
ordering/reassembly ownership. It is an audit rather than direct
implementation because payload capture, last-beat semantics, different-ID
interleaving, and concrete-ID/per-ID ordering queues are coupled.

No parser, generator, `.isf`, `.fsm`, HDL, check JSON, or semantic JSON
behavior changed in `.42`. Full-manager behavior, profile aliases,
queued/blocking policy, direct backend lowering, and VHDL remain deferred
unless a later exact owner selects them.
