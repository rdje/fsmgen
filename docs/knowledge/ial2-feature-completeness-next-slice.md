---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice aligns auto-ID lifecycle residue
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after generated AXI write BID response demux?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.31?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should same-ID ordering come before report residue alignment?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, auto-id, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md; docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.32|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.31|auto_id_lifecycle\\.residue|residue alignment|generated write BID response-demux behavior' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, ID-family metadata,
transaction-envelope metadata, transaction event dispatch, concrete
transaction ID assertion, auto-ID lifecycle metadata, bounded auto-ID
request-ID drive, write response-demux metadata, IAL1 rule-pulse action, and
generated write `BID` response-demux behavior, the next active leaf is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.32`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.31` selected `.32` after reading the
post-`.30` report. The behavior-bearing `response_demux` report is current,
and `id_response_rule_engine.residue` no longer lists `response_demux`, but
`auto_id_lifecycle.residue` still lists `response_demux`. That is stale
because generated demux completion pulses now drive auto-ID release.

`.32` should remove `response_demux` from `auto_id_lifecycle.residue` when
explicit `response_demux.generated_behavior` is true, while proving generated
`.isf`, `.fsm`, and SystemVerilog HDL text do not change.

The full AXI manager is not implemented yet. Same-ID ordering, read `RID`
demux, read-data interleaving/reassembly, bursts, queued/blocking policy,
profile aliases, full-manager syntax, and VHDL remain future exact-owner work.
VHDL stays deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is
feature-complete enough to reopen backend parity.
