---
id: ial2-axi-manager-multiple-mixed-depth3-response-demux-readiness-audit
title: Multiple or mixed depth-3 queue-head response-demux is ready for direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.173 decide?"
  - "what is the next IAL2 frontier after the multiple or mixed depth-3 response-demux audit?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.174 implement?"
  - "are multiple depth-3 same-ID queue-head response-demux groups ready?"
date: 2026-06-18
status: current
tags: [ial2, axi, manager, response-demux, queue-head, depth-3, readiness]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.173|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.174|MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT|multi_depth3_same_id_queue_head_response_demux|mixed_depth3_depth2_same_id_queue_head_response_demux' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.173` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.174`, direct bounded implementation of
generated multiple or mixed depth-3 concrete same-ID queue-head response-demux
for response-demux-only read single-beat, read burst-last, and write families.

The audit found that the remaining generation blocker is local to
`_build_same_id_issue_order_queue_behavior`: depth-3 shapes still require
`@$groups == 1`, while downstream storage, transition, assertion,
response-demux, and report helpers already iterate generated queue groups and
their local depths. Temporary probes for two depth-3 groups and mixed
depth-3/depth-2 groups across all three response-demux-only family scopes
strict-check with zero diagnostics but remain selected-not-generated with
`generated_same_id_queue_head_demux` residue.

`.174` should add public support-accounted samples for read single-beat, read
burst-last, and write two-depth-3 and mixed depth-3/depth-2 queue groups,
update focused tests and user-facing documentation, and preserve read-data,
burst-length, runtime-validation, multi-beat payload, mixed auto-ID,
group-local enqueue widening, direct backend, VHDL, and backend-language
variants behind future exact owners.
