---
id: ial2-axi-manager-same-id-issue-order-queue-admitted-request-pulses-first-slice
title: Same-ID issue-order queue admitted request pulses first slice shipped boundary
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.98 ship?"
  - "how does FSMGen report issue-order-queue admitted request pulses?"
  - "does issue-order-queue accept same-ID reuse after admitted request pulses?"
  - "what is the admitted request pulse guard?"
  - "does issue-order-queue use can_accept for admitted enqueue?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, admitted-request, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.98|IAL2-FEATURE-COMPLETENESS-FRONTIER\.99|admitted_request_boundary|admitted_request_pulses_generated|axi0_r0_admitted_request_pulse_q|can_accept|generated_queue_behavior' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.98` shipped admitted request pulse
generation for selected AXI same-ID `issue-order-queue` families.

For each concrete transaction in the selected family, FSMGen emits one
internal scalar storage pulse target and one pulse rule. The guard is:

```lisp
(& REQUEST_EVENT (| (< PENDING_STORAGE MAX_PENDING) COMPLETION_FANIN))
```

For the public sample this becomes:

```lisp
(& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
```

The boundary deliberately does not read `axi0_read_can_accept` or
`axi0_write_can_accept`.

Schedule JSON reports the family policy with
`enforcement: admitted_request_boundary`,
`implementation_status: admitted_request_pulses_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`, and an
`admitted_request_boundary` payload containing the pending storage,
`max_pending`, completion fan-in, selected request events, generated pulse
rules, and any request mutual-exclusion assertions.

Accepted concrete same-ID reuse remains unshipped. Duplicated concrete
same-ID reuse still fails closed until queue state and queue-head response
demux ship. `.98` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.99`, the next AXI manager selector.
