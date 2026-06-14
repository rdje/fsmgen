---
id: ial2-axi-manager-same-id-queue-head-demux-contract
title: Same-ID queue-head demux reuses response-demux family arms
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.102 decide?"
  - "how is AXI same-ID queue-head response demux selected?"
  - "does same-ID queue-head demux add a new top-level clause?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.105?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.102|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.103|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.104|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.105|bounded_write_bid_queue_head_demux_contract|bounded_read_rid_queue_head_demux_contract|selected_not_generated|same-family auto-ID' docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.102` selected the public/report contract
for AXI concrete same-ID queue-head response demux.

The selector reuses the existing `response-demux` read/write family arms. It
does not add a new top-level `queue-demux` clause. A queue-head interpretation
is selected only when the same family selects `concrete-id-reuse
issue-order-queue`, has duplicate concrete-ID groups, and does not also
require same-family auto-ID response demux in the first contract.

The selected report modes are `bounded_write_bid_queue_head_demux_contract`
and `bounded_read_rid_queue_head_demux_contract`, with generated behavior false
and `selected_not_generated` metadata until later behavior owners ship queue
state plus queue-head demux.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.103` has since shipped the
selected-not-generated metadata/static validation and public sample. `.104`
audited generated behavior readiness and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated same-ID queue state
and queue-head behavior slice selection.
