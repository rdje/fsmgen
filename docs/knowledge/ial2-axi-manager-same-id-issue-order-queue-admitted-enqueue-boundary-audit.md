---
id: ial2-axi-manager-same-id-issue-order-queue-admitted-enqueue-boundary-audit
title: Same-ID issue-order queue admitted enqueue audit selected admitted request pulses
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.97 select?"
  - "what comes after same-ID issue-order queue metadata?"
  - "what is the admitted enqueue boundary for AXI same-ID issue-order queues?"
  - "should FSMGen implement queue state before admitted request pulses?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.98?"
  - "what came after the admitted enqueue audit?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, admitted-request, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.97|IAL2-FEATURE-COMPLETENESS-FRONTIER\.98|IAL2-FEATURE-COMPLETENESS-FRONTIER\.99|IAL2-FEATURE-COMPLETENESS-FRONTIER\.100|admitted_request_boundary|admitted request|admitted per-transaction|can_accept|queue-head response demux|queue-head demux|generated_queue_behavior' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.97` audited the admitted enqueue boundary
after selected-not-generated `issue-order-queue` metadata shipped in `.96`.

It selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`, admitted
per-transaction request pulse generation, as the next prerequisite before
per-ID queue state or queue-head response-demux behavior.

`.98` has now shipped. The generated pulses are derived from transaction
request event, current capacity storage, family `max-pending`, and same-cycle
completion fan-in, not from the generated `can_accept` output value.

Duplicated concrete same-ID reuse remains fail-closed until queue state and
queue-head response demux ship. `.99` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.100`, AXI same-ID issue-order queue state
and queue-head demux readiness audit, as the active frontier after admitted
request pulses.
