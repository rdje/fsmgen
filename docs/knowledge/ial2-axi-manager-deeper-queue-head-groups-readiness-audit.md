---
id: ial2-axi-manager-deeper-queue-head-groups-readiness-audit
title: IAL2 deeper queue-head readiness selects depth-3 read single-beat implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.148 decide?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.149?"
  - "are depth-3 concrete same-ID queue-head groups implemented?"
  - "why does depth-3 queue-head need shared queue-state generalization?"
  - "what happens to depth-3 queue-head read-data today?"
date: 2026-06-16
status: current
tags: [ial2, axi, manager, queue-head, same-id, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.148|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.149|depth-3|selected_not_generated|requires generated read response_demux metadata|slot0|slot1|slot2' docs/AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.148` audited generated concrete same-ID
queue-head groups deeper than two slots and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.149`.

The selected `.149` owner is generated read single-beat depth-3 concrete
same-ID queue-head response-demux through a generalized shared same-ID
issue-order queue-state core. The first behavior boundary is one read family
group with three read transactions at computed depth `3`, compact one-hot
slots `slot0` through `slot2`, and response-demux-only completion pulses.

Depth-3 groups are not implemented yet. Temporary read single-beat, read
burst-last, and write depth-3 probes pass strict check and semantic export as
selected-not-generated metadata; temporary depth-3 read-data probes fail
closed with `read_data requires generated read response_demux metadata`.

The audit found the current queue builder, storage allocation, transition
matrix, state/full helpers, and assertions are specialized around two
transactions and slots `0`/`1`. A safe depth-3 behavior slice must generalize
the shared queue-state next-state function before exposing the first public
depth-3 sample.
