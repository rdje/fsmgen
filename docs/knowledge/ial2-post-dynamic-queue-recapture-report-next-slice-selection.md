---
id: ial2-post-dynamic-queue-recapture-report-next-slice-selection
title: Depth-3 all-dynamic write queue is the next post-recapture report audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.480 select?"
  - "what is the next dynamic same-ID issue-order queue widening after report alignment?"
  - "why choose dynamic write depth-3 before mixed queues or scoreboards?"
  - "what does .481 own?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_REPORT_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_IDENTITY_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.480|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.481|POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION|depth-3|three-transaction|mixed dynamic/static|scoreboard' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_QUEUE_RECAPTURE_REPORT_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`.480` selects `.481`, readiness audit for generated all-dynamic write BID
same-ID `issue-order-queue` cardinality widening from the shipped
two-transaction dynamic queue to one bounded depth-3, three-transaction queue.

Depth-3 dynamic write is selected before mixed dynamic/static queues or
scoreboards because it exercises queue cardinality without adding read-side
`RLAST`, read-data, raw-`ARLEN`, validation, output-bank, reserved-static-ID,
or scoreboard semantics.

`.481` owns the audit only; no parser, generator, sample, support-accounting,
report JSON, test, HDL/runtime, backend-language, direct backend, mixed queue,
scoreboard, or VHDL behavior changes in `.480`.
