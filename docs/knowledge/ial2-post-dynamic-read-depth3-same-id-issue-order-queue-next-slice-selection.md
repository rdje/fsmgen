---
id: ial2-post-dynamic-read-depth3-same-id-issue-order-queue-next-slice-selection
title: Post depth-3 dynamic read queue selector chooses burst-last readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.486 select?"
  - "what owns generated dynamic read burst-last depth-3 queue readiness?"
  - "why is read burst-last depth-3 next after read single-beat depth-3?"
  - "does the next dynamic queue slice depend on sv2v?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, cardinality, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/knowledge/ial-contracts-backend-language-neutral.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.486|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.487|POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION|read burst-last.*depth-3|read_rid_rlast|sv2v|external converter' docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial-contracts-backend-language-neutral.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t t/1437-axi-ial2-manager-capacity-status-generator.t t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`.486` selects `.487`, readiness audit for generated all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` depth-3 behavior.

This is the smallest post-`.485` widening because `.485` already proves the
read-side depth-3 compact runtime-ID queue for single-beat `RID` completion,
and `.463` already proves the two-transaction dynamic read burst-last queue.
The selected audit adds only the depth-3 version of the RLAST-gated final
selected-dequeue path, while leaving read-data, mixed dynamic/static queues,
scoreboards, arbitrary cardinality, direct backend behavior, backend-language
variants, external converter dependencies, and VHDL deferred.

The next slice does not select `sv2v` or any external converter dependency.
FSMGen-owned generation/lowering remains the default; external converters are
future audit candidates only under the backend portability frontier.
