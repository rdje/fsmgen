---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is same-ID issue-order queue metadata
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what is the next IAL2 PNT task?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.96?"
  - "what is the next AXI manager slice?"
  - "what is the next AXI manager task after same-ID issue-order queue contract selection?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, ordering, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/knowledge/ial2-common-vs-profile-factoring.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.95|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.96|issue-order-queue|selected_not_generated|generated_queue_behavior|common semantic core' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md docs/knowledge/ial2-common-vs-profile-factoring.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.95` audited generated AXI same-ID
`issue-order-queue` behavior readiness.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`. It
implements metadata-first parser/report support for `issue-order-queue` with
`implementation_status: selected_not_generated`, `accepted_same_id_reuse:
false`, and `generated_queue_behavior: false`.

Generated accepted same-ID reuse remains unshipped. Duplicated concrete
same-ID transactions must still fail closed until generated queue-head
behavior exists.

The IAL2 factoring stance remains that common constructs should be promoted
only after compatible reuse is proven across multiple profiles.
