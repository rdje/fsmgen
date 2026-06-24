---
id: ial2-dynamic-same-id-policy-contract-selection
title: Dynamic same-ID policy contract selects dynamic-id-reuse reject first
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.434 select?"
  - "what is the public dynamic same-ID policy spelling?"
  - "does concrete-id-reuse cover dynamic transaction IDs?"
  - "which dynamic same-ID policy value is selected first?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, policy, selector]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.434|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.435|DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION|dynamic-id-reuse|dynamic_id_reuse_policy' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.434` selects the public dynamic same-ID
policy spelling `(dynamic-id-reuse reject)` as an additive family-local clause
under `(same-id-ordering ...)`, distinct from existing `concrete-id-reuse`.

The first selected value is only `reject`; `issue-order-queue` and
`scoreboard` remain unsupported future dynamic policy values. `.434` changes
no behavior and selects `.435`, readiness audit for metadata-first
parser/report support before any parser or generator implementation.
