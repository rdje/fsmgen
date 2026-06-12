---
id: ial2-axi-manager-same-id-ordering-readiness-selection
title: Same-ID ordering readiness follows generated write response demux
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.33 select?"
  - "what comes after generated write BID response demux and residue alignment?"
  - "is same-ID ordering implemented now?"
  - "what is the next step for AXI same-ID ordering?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, same-id, ordering, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.33|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.34|same-ID ordering readiness|same_id_ordering|AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION' docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.33` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.34`, an AXI same-ID ordering readiness
audit.

The selector read the post-`.32` response-demux schedule report, AXI ID/order
evidence, rule matrix, generated write response-demux behavior note, auto-ID
residue-alignment note, mdBook, roadmap, and generator report residue. After
generated write `BID` demux and auto-ID residue alignment, `same_id_ordering`
is the common remaining ID/auto-ID/write-demux residue.

Same-ID ordering is not implemented by `.33`. The `.34` readiness audit must
choose the first exact owner before behavior changes: static/report
classification, generated assertions, allocator constraints, per-ID
issue-order queues or scoreboards, or a smaller IAL1/IAL0/SystemVerilog
prerequisite.

Read `RID` response demux, read-data interleaving/reassembly, bursts,
queued/blocking policy, profile aliases, full-manager syntax, and VHDL remain
future exact-owner work.
