---
id: ial2-axi-manager-same-id-reuse-policy-contract-selection
title: Same-ID reuse policy contract selects explicit reject syntax
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.91 select?"
  - "what is the AXI same-ID reuse policy syntax?"
  - "what comes after AXI same-ID reuse policy contract selection?"
  - "does same-ID reuse reject policy generate queues?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, policy, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.91|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.92|SAME_ID_REUSE_POLICY_CONTRACT_SELECTION|SAME_ID_REJECT_POLICY_FIRST_SLICE|same-id-ordering|concrete-id-reuse reject' docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.91` selected an optional AXI-profile-local
`same-id-ordering` clause under `manager-capacity-status`:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject))
  (write
    (concrete-id-reuse reject)))
```

The first accepted policy is `reject`. It documents that authored
concrete-ID same-ID reuse is intentionally rejected by public source policy.
It does not accept same-ID reuse, generate per-ID queues, or change HDL
behavior for valid sources.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.92` shipped parser/report metadata plus
static validation for the explicit reject policy. Future `issue-order-queue`
or `scoreboard` behavior remains deferred.
