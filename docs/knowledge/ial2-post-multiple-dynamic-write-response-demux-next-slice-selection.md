---
id: ial2-post-multiple-dynamic-write-response-demux-next-slice-selection
title: Post multiple dynamic write demux selector chooses read audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.248 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.249?"
  - "what is next after multiple dynamic write response-demux?"
  - "why audit multiple dynamic read response-demux next?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, read-response-demux, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.248|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.249|POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|multiple dynamic read response-demux|_response_demux_dynamic_read_transaction|read-data coverage path' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.248` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.249`, readiness audit for multiple dynamic
read response-demux behavior after `.247` shipped bounded multiple dynamic
write response-demux.

The next owner is an audit, not an implementation, because the read side has
`single_beat` and `burst_last` response scopes, optional `RLAST`, raw matched
`RID` beat counting, scalar read-data capture, report-only/runtime `ARLEN`,
and multi-beat output-bank coupling. The live read helper still accepts only
one dynamic read transaction and no additional read transactions, and dynamic
read-data coverage still expects exactly one generated dynamic completion.

Mixed dynamic/static demux, same-cycle request widening, release-and-recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain deferred.
