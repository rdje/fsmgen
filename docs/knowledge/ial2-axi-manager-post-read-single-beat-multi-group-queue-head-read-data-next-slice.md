---
id: ial2-axi-manager-post-read-single-beat-multi-group-queue-head-read-data-next-slice
title: IAL2 selects deeper queue-head readiness after single-beat multi-group read-data
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.147 select?"
  - "what comes after read single-beat multi-group queue-head read-data?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.148?"
  - "why are deeper queue-head groups an audit first?"
  - "are deeper concrete same-ID queue-head groups implemented?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, same-id, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.147|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.148|deeper than two|deeper concrete same-ID|_same_id_issue_order_queue_transition_specs|slots `0` and `1`|slot0|slot1' docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.147` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.148`, readiness audit for generated
concrete same-ID queue-head groups deeper than two slots.

The selector made no behavior changes. It read the shipped `.146` read-data
behavior, adjacent queue-head response-demux/read-data behavior, implementation
code, tests, public samples, support accounting, README, roadmap, mdBook, task
tree, Memory, and Knowledge Map.

Live reports show the current generated queue-head families are all bounded
depth-2 shapes. Code inspection found that duplicate concrete-ID group
metadata can describe a deeper group, but generated queue-head behavior still
rejects non-depth-2 groups and its storage, transition matrix, state/full
helpers, and assertions are specialized around slots `0` and `1`.

Deeper concrete same-ID queue-head groups are not implemented yet. `.148`
must audit deeper read/write response-demux and read-data consumers,
diagnostics, report/residue movement, support accounting, semantic JSON,
generated HDL, docs/book impact, and rollback before any behavior owner is
selected.
