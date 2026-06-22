---
id: ial2-post-dynamic-multi-beat-next-slice-selection
title: Post dynamic multi-beat selector chooses multiple/mixed dynamic demux audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.244 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.245?"
  - "what is next after dynamic multi-beat output banks?"
  - "why audit multiple/mixed dynamic response demux next?"
date: 2026-06-22
status: current
tags: [ial2, axi, dynamic-id, response-demux, read-data, multi-beat, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.244|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.245|POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION|multiple/mixed dynamic response-demux|response_demux\\.residue: \\[same_id_ordering\\]|read_data\\.residue: \\[\\]' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_MULTI_BEAT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.244` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.245`, readiness audit for
multiple/mixed dynamic response-demux behavior after generated dynamic
multi-beat output banks.

The selector read the `.243` behavior and current schedule report. The
selected dynamic multi-beat sample now has empty `read_data.residue` and keeps
only `same_id_ordering` in `response_demux.residue`; remaining dynamic
transaction-ID residue is multiple dynamic read/write transactions, mixed
dynamic/static response demux, same-cycle recapture, same-ID ordering, queues,
and scoreboards.

Multiple/mixed dynamic response demux is the next prerequisite because later
dynamic same-ID ordering, queues, and scoreboards need a settled dynamic
response ownership model: per-transaction selected-ID/busy state,
simultaneous request capture, deterministic response matching, release timing,
and same-cycle recapture semantics.

`.244` changes no parser, generator, PPIF sample, support accounting,
validation behavior, generated artifact, test, schedule/check/semantic JSON,
or HDL behavior.
