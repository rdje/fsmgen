---
id: ial2-axi-manager-same-id-issue-order-queue-metadata-first-slice
title: Same-ID issue-order queue metadata first slice shipped selected-not-generated support before admitted pulses
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.96 ship?"
  - "does FSMGen accept issue-order-queue in same-id-ordering?"
  - "how does FSMGen report issue-order-queue metadata?"
  - "does issue-order-queue accept duplicated concrete same-ID reuse?"
  - "what is the AXI same-ID issue-order queue metadata sample?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, ppif, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.96|IAL2-FEATURE-COMPLETENESS-FRONTIER\.98|IAL2-FEATURE-COMPLETENESS-FRONTIER\.99|IAL2-FEATURE-COMPLETENESS-FRONTIER\.100|issue-order-queue|issue_order_queue|selected_not_generated|admitted_request_boundary|admitted_request_pulses_generated|accepted_same_id_reuse|generated_queue_behavior|axi_manager_capacity_status_same_id_issue_order_queue_policy|queue-head demux' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif perl/FSM/Adapter/IAL2/PPIF.pm
  perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.96` shipped metadata-first AXI same-ID
`issue-order-queue` support.

PPIF accepts `issue-order-queue` as a `concrete-id-reuse` value under
read/write `same-id-ordering` family arms. At `.96`, schedule JSON reported
normalized `policy: issue_order_queue`, `enforcement: not_generated`,
`implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.

Current `.98` behavior keeps the same public sample but overlays generated
admitted request pulse metadata: `enforcement: admitted_request_boundary`,
`implementation_status: admitted_request_pulses_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.

The support-accounted sample is
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`.

Duplicated concrete same-ID reuse remains fail-closed under the selected
policy until generated issue-order queue behavior ships. `.98` shipped
admitted per-transaction request pulse generation; queue state and queue-head
response-demux behavior remain deferred. `.99` selected `.100`, the readiness
audit that must scope queue state and queue-head demux before generated
behavior changes.
