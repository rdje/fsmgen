---
id: ial2-post-dynamic-read-burst-last-same-id-issue-order-queue-next-slice-selection
title: Post dynamic read burst-last queue selector chooses read-data audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.464 select?"
  - "what comes after dynamic read burst-last same-ID issue-order queue behavior?"
  - "why is read-data over generated dynamic read queues next?"
  - "what remains unsupported after the post dynamic read burst-last queue selector?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, read-data, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.464|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.465|POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|generated_dynamic_issue_order_queue_demux_last_beat|read-data routing over generated dynamic read same-ID|read_data.read dynamic coverage requires generated dynamic read' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SINGLE_BEAT_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DATA_BEHAVIOR.md docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.464` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.465` as a readiness audit for read-data
routing over generated dynamic read same-ID `issue-order-queue` response-demux
pulses.

The selector changes no behavior. It follows `.463` because generated dynamic
read same-ID queues now ship both single-beat `RID` and burst-last `RID &&
RLAST` completion sources, while read-data over generated dynamic read queues
is still explicitly future.

`.465` must decide whether the first owned read-data behavior should be scalar
single-beat over generated dynamic read single-beat queues, scalar last-beat
over generated dynamic read burst-last queues, a paired bounded scalar
contract, a report/static cleanup prerequisite, a lower-layer prerequisite, or
deferral. Read-data generation, raw `ARLEN`, runtime validation, multi-beat
output banks, recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners until selected.
