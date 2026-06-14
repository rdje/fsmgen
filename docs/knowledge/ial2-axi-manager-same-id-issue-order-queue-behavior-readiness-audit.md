---
id: ial2-axi-manager-same-id-issue-order-queue-behavior-readiness-audit
title: Same-ID issue-order queue behavior readiness selects metadata-first support
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.95 select?"
  - "is AXI same-ID issue-order queue generated behavior ready?"
  - "what is the next step after same-ID issue-order queue behavior readiness?"
  - "can issue-order-queue ship as metadata before generated queue behavior?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.96?"
  - "what comes after same-ID issue-order queue metadata?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, response-demux, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.95|IAL2-FEATURE-COMPLETENESS-FRONTIER\.96|IAL2-FEATURE-COMPLETENESS-FRONTIER\.97|issue-order-queue|selected_not_generated|accepted_same_id_reuse|generated_queue_behavior|admitted per-transaction' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.95` audited AXI same-ID
`issue-order-queue` behavior readiness. It concluded that generated
queue-head behavior is not ready as a direct next slice.

The blockers are in the AXI manager generator boundary, not the lower
IAL1/IAL0/SystemVerilog substrate: current response demux is auto-ID
selected-ID matching, concrete transactions have no queue-head state, and
queue enqueue needs an admitted per-transaction request boundary.

`.95` selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, metadata-first
parser/report support for `issue-order-queue`. That slice may accept the
spelling and report `implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.

Duplicated concrete same-ID reuse must still fail closed until generated
queue-head behavior ships.

`.96` shipped that metadata-first support and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.97`, admitted per-transaction enqueue
boundary readiness, as the next prerequisite audit before generated queue-head
behavior.
