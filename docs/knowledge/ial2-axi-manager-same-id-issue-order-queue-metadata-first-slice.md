---
id: ial2-axi-manager-same-id-issue-order-queue-metadata-first-slice
title: Same-ID issue-order queue metadata first slice shipped selected-not-generated support
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.96 ship?"
  - "does FSMGen accept issue-order-queue in same-id-ordering?"
  - "how does FSMGen report issue-order-queue metadata?"
  - "does issue-order-queue accept duplicated concrete same-ID reuse?"
  - "what is the AXI same-ID issue-order queue metadata sample?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, issue-order, queue, ppif, report, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.96|issue-order-queue|issue_order_queue|selected_not_generated|accepted_same_id_reuse|generated_queue_behavior|axi_manager_capacity_status_same_id_issue_order_queue_policy' docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.96` shipped metadata-first AXI same-ID
`issue-order-queue` support.

PPIF accepts `issue-order-queue` as a `concrete-id-reuse` value under
read/write `same-id-ordering` family arms. Schedule JSON reports normalized
`policy: issue_order_queue`, `enforcement: not_generated`,
`implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.

The support-accounted sample is
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`.

Duplicated concrete same-ID reuse remains fail-closed under the selected
policy until generated issue-order queue behavior ships. `.96` advanced the
frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.97`, admitted
per-transaction enqueue boundary readiness.
