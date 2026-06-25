---
id: ial2-dynamic-same-id-issue-order-queue-policy-readiness-audit
title: Dynamic same-ID issue-order queue policy needs public contract selection
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.448 select?"
  - "can dynamic-id-reuse issue-order-queue be implemented directly?"
  - "why does dynamic issue-order queue need a contract before parser changes?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.449?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, audit]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_ONE_DYNAMIC_MIXED_DYNAMIC_SAME_ID_REJECT_MAPPING_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.448|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.449|DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT|dynamic-id-reuse issue-order-queue|selected_not_generated|generated_queue_behavior' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_QUEUE_POLICY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.448` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.449`, public dynamic same-ID
`issue-order-queue` policy contract selection.

The audit changes no behavior. It does not accept
`dynamic-id-reuse issue-order-queue` directly because dynamic queues need an
explicit source/report contract before parser or generated behavior changes.
The concrete same-ID queue-head path is the closest precedent, but dynamic IDs
are runtime values rather than statically enumerable concrete groups.

`.449` must decide whether metadata-first parser/report support is allowed,
what selected-not-generated report fields look like, and how the policy keeps
`accepted_same_id_reuse` and `generated_queue_behavior` false until generated
dynamic queue behavior ships. Dynamic `scoreboard` remains a separate later
policy owner.
