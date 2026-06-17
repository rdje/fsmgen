---
id: ial2-axi-manager-post-read-burst-last-depth3-response-demux-next-slice-selection
title: Read-data over read burst-last depth-3 queue-head response-demux is the next IAL2 audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.157 select?"
  - "what is the next IAL2 frontier after read burst-last depth-3 queue-head response-demux?"
  - "why is read-data over read burst-last depth-3 an audit first?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3]
evidence: docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.157|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.158|read-data over read burst-last depth-3|POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION|queue-head last-beat coverage requires one or more depth-2' docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.157` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.158`, readiness audit for generated
read-data over read burst-last depth-3 queue-head response-demux.

The selector confirmed `.156` is generated at depth `3` and remains
response-demux-only. Existing read burst-last queue-head read-data remains
generated at depth `2`, while the only depth-3 queue-head read-data sibling
is the read single-beat shape.

A temporary last-beat read-data-over-`.156` probe fails closed at the current
coverage gate: burst-last queue-head read-data requires one or more depth-2
concrete same-ID read queue groups. That is why `.158` is a readiness audit
before any behavior-bearing implementation.
