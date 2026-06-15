---
id: ial2-axi-manager-multi-group-queue-head-response-demux-readiness-audit
title: IAL2 multi-group queue-head response-demux audit selected generated read burst-last behavior
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.123 select?"
  - "can AXI queue-head response demux support multiple concrete read-ID groups?"
  - "what is the boundary for multiple queue-head response-demux groups?"
  - "does the multi-group queue-head slice include read-data?"
  - "does the multi-group queue-head slice allow simultaneous group-local enqueue?"
date: 2026-06-15
status: current
tags: [ial2, axi, manager, queue-head, same-id, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.123|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.124|multi-group queue-head response-demux|family-wide admitted-request onehot|generated multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux groups|generated_same_id_queue_head_demux' docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.123` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.124`, generated multiple independent read
burst-last depth-2 concrete same-ID queue-head response-demux groups.

The audit found the queue-head planner already detects multiple duplicate
concrete read-ID groups and selected completion signals, while
`_build_same_id_issue_order_queue_behavior` still rejects more than one group.
Downstream queue storage, transition, assertion, response-state,
response-demux, report, and residue helpers already iterate groups once
behavior exists.

`.124` is read-family, burst-last, response-demux-only, and depth-2 only. It
must keep the existing family-wide admitted-request onehot boundary, so it
must not claim simultaneous group-local same-cycle enqueue widening. It also
excludes read-data over multiple groups, same-family auto-ID plus concrete
queue-head demux, deeper queues, write-family or read single-beat multi-group
queue-head behavior, packed outputs, direct backend, and VHDL.
