---
id: ial2-post-mixed-dynamic-static-read-demux-next-slice-selection
title: Post mixed dynamic/static read demux selector chooses burst-last readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.277 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.278?"
  - "what follows mixed dynamic/static read single-beat response-demux?"
  - "what is the next IAL2 slice after mixed dynamic/static read demux?"
  - "why is mixed dynamic/static read RLAST readiness next?"
date: 2026-06-23
status: current
tags: [ial2, axi, dynamic-id, static-id, read-response-demux, rlast, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.277|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.278|POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION|mixed dynamic/static read burst-last|RID && RLAST|response-scope single-beat' docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DEMUX_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.277` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.278`, readiness audit for bounded mixed
dynamic/static read burst-last `RID && RLAST` response-demux.

The selector follows `.276`, which shipped generated bounded mixed
dynamic/static read single-beat `RID` response-demux for exactly one dynamic
read transaction plus one concrete static read transaction. Burst-last remains
fail-closed in that behavior because the shipped mixed branch accepts only
`response-scope single-beat`.

`RID && RLAST` readiness is next because read-data, raw `ARLEN`, runtime
beat-count validation, and multi-beat output banks all depend on a settled
final-beat completion or matched-beat boundary. The audit must decide whether
the existing all-dynamic burst-last helpers and the `.276` mixed
dynamic/static static-ID reservation assertions compose directly, or whether
a narrower public contract or helper prerequisite is required first.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in `.277`.
