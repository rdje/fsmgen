---
id: ial2-post-dynamic-transaction-id-metadata-next-slice-selection
title: Post dynamic transaction-ID metadata selector chooses capture and matching readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.220 select?"
  - "what comes after dynamic transaction-ID metadata?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.221?"
  - "does FSMGen implement dynamic ID capture after id dynamic metadata?"
  - "why is dynamic response matching audited before generated behavior?"
date: 2026-06-22
status: current
tags: [ial2, axi, manager, dynamic-id, response-matching, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_READINESS_AUDIT.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.220|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.221|POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION|dynamic transaction-ID capture|response matching readiness|selected_not_generated|dynamic_transaction_id_behavior' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_TRANSACTION_ID_METADATA_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.220` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.221`, readiness audit for generated
dynamic transaction-ID capture and response matching.

The selector follows the `.219` metadata-only `(id dynamic)` support. Dynamic
IDs now parse and report user-supplied request/response ID metadata, but
generated capture, outstanding tracking, response matching, queues,
scoreboards, read-data routing, and HDL behavior remain unsupported residue
under `dynamic_transaction_id_behavior`.

`.221` must audit the first safe behavior or prerequisite before implementation:
capture timing at the admitted request point, outstanding-state lifetime,
response-match/completion semantics, runtime assertions, generated artifact
boundaries, diagnostics, support accounting, and mdBook validation. It must not
change parser/generator/sample/test/HDL behavior unless it creates a later
implementation leaf.
