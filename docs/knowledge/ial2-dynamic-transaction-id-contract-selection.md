---
id: ial2-dynamic-transaction-id-contract-selection
title: Dynamic transaction IDs use transaction-local id dynamic contract
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.217 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.218?"
  - "what is the public dynamic transaction ID contract?"
  - "how should PPIF spell a dynamic transaction ID?"
  - "does id dynamic generate dynamic ID queues?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.217|IAL2-FEATURE-COMPLETENESS-FRONTIER\.218|DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION|id dynamic|metadata-first dynamic transaction-ID' docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.217` selected transaction-local
`(id dynamic)` as the public dynamic/user transaction-ID contract and advanced
the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.218`, readiness audit for
metadata-first dynamic transaction-ID parser/report support.

The selected dynamic ID source is the family request-ID signal declared in
`id-families` at the transaction's admitted request point. The selected
normalized report vocabulary uses `policy: dynamic`, `ownership:
user_supplied`, `request_id_source`, `response_id_signal`, and
`implementation_status: selected_not_generated`.

`(id dynamic)` does not generate dynamic ID capture, response matching,
same-ID policy, generalized per-ID queues, scoreboards, support accounting,
generated artifacts, validation, tests, or HDL behavior. Those remain later
task-tree-owned boundaries.
