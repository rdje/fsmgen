---
id: ial2-post-mixed-dynamic-static-write-demux-next-slice-selection
title: Post mixed dynamic/static write demux selector chooses read demux readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.273 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.274?"
  - "what follows mixed dynamic/static write response-demux?"
  - "what is the next IAL2 slice after mixed dynamic/static write demux?"
  - "why is mixed dynamic/static read demux next?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_RESPONSE_DEMUX_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.273|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.274|POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION|mixed dynamic/static read response-demux|response_demux\\.read dynamic ID matching requires every read transaction' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_WRITE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.273` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.274`, readiness audit for mixed
dynamic/static read response-demux.

The selector follows `.272`, which shipped generated bounded mixed
dynamic/static write `BID` response-demux for exactly one dynamic write
transaction plus one concrete static write transaction. The read side still
fails closed when a selected read family mixes dynamic and static/concrete
transaction IDs, with the diagnostic that dynamic read matching requires every
read transaction to use dynamic IDs.

Read-side mixed ownership needs a readiness audit before contract or behavior
selection because read response-demux can mean single-beat `RID`, burst-last
`RID && RLAST`, scalar read-data over generated completions, raw `ARLEN`
capture, runtime beat-count/`RLAST` validation, or multi-beat output-bank
lane capture. `.274` must decide the first safe read shape or prerequisite
and record diagnostics, report vocabulary, validation, rollback, docs,
Knowledge Map impact, and explicit residue.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in `.273`.
