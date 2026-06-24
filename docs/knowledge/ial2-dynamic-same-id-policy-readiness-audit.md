---
id: ial2-dynamic-same-id-policy-readiness-audit
title: Dynamic same-ID policy readiness selects public contract before queues
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.433 select?"
  - "what comes after dynamic same-ID readiness audit?"
  - "why not implement dynamic same-ID queues after .433?"
  - "what is the next owner for dynamic same-ID ordering?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, policy, selector]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_ISSUE_ORDER_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_TRANSACTION_ID_METADATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.433|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.434|DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT|dynamic same-ID policy|concrete-id-reuse|same_id_ordering' docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_POLICY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.433` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.434`, public dynamic same-ID policy
contract selection before dynamic per-ID queues, scoreboards, parser/report
implementation, or generated behavior.

The audit changes no behavior. It records that generated bounded dynamic and
mixed response-demux, read-data, multi-beat, and recapture substrate now
exists, but dynamic same-ID reuse still lacks a public source/report policy
distinct from concrete `concrete-id-reuse`. Direct queues or scoreboards
remain premature until `.434` chooses the dynamic policy spelling, report
fields, diagnostics, and first later owner.
