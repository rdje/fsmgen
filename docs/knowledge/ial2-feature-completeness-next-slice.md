---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is same-ID issue-order queue behavior readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.95?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID issue-order queue contract selection?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.94|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.95|issue-order-queue|queue-head response-demux|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.94` selected the public AXI same-ID
`issue-order-queue` policy contract before parser/report metadata or generated
queue behavior.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`. It audits
whether the selected `issue-order-queue` contract can safely ship as
parser/report metadata first, must ship parser support together with generated
queue-head behavior, or needs a smaller prerequisite such as concrete-ID
response-demux refactoring, queue-state helper substrate, or report-contract
restructuring.

Generated accepted same-ID reuse remains unshipped. Metadata-only
intermediate work must not report `accepted_same_id_reuse: true` or
`generated_queue_behavior: true`.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
