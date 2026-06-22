---
id: ial2-multiple-dynamic-response-demux-readiness-audit
title: Multiple dynamic demux readiness selects write contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.245 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.246?"
  - "is multiple dynamic response-demux ready for direct implementation?"
  - "why select multiple dynamic write response-demux contract selection?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, response-demux, readiness, selection]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.245|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.246|MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT|bounded multiple dynamic write response-demux|supports exactly one dynamic write transaction|_response_demux_dynamic_write_transaction|_response_demux_match_expr' docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.245` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.246`, public contract selection for
bounded multiple dynamic write response-demux behavior.

The audit found that generated dynamic storage, capture/release rules,
response completion rules, and transaction-state iteration are already
state-list shaped after normalization. The current blocker is the public
ambiguity contract: dynamic response matching uses `busy && response_id ==
selected_id`, so two active dynamic transactions with the same captured ID
could both match one raw response unless the selected contract defines
same-ID conflict assertions, request guards, or a later queue/scoreboard.

The next step is contract selection rather than direct implementation.
Write response-demux is the first bounded family because it avoids `RLAST`,
read-data, burst-length, and per-beat output-bank coupling. Multiple dynamic
read demux, mixed dynamic/static demux, dynamic same-ID queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain deferred.
