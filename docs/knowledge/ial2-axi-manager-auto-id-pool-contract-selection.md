---
id: ial2-axi-manager-auto-id-pool-contract-selection
title: AXI manager auto-ID lifecycle uses an explicit bounded pool contract
answers:
  - "what syntax was selected for AXI auto-ID lifecycle?"
  - "does id auto become behavior-bearing automatically?"
  - "what is the auto-id-lifecycle contract?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.22?"
  - "how are AXI request and response ID signals directed for auto-ID lifecycle?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, auto-id, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'auto-id-lifecycle|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.22|generated_behavior: false|request_id_direction: generated_output|response_id_direction: generated_input|Existing \\(id auto\\) transactions remain structural/report-only' docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.21` selected an explicit bounded
`auto-id-lifecycle` clause under `manager-capacity-status`.

The selected public syntax is:

```text
(auto-id-lifecycle
  (write (pool 0 1))
  (read  (pool 0 1 2 3)))
```

Existing `(id auto)` transactions do not become behavior-bearing
automatically. Without `auto-id-lifecycle`, they remain structural/report-only
metadata.

For future generated behavior, request ID signals are manager-owned generated
outputs (`AWID`/`ARID`) and response ID signals remain generated inputs
(`BID`/`RID`). The selected allocator is deterministic first-free in author
pool order, with single-active logical transactions and completion-event
release.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.22` owns the next step: implement the
additive public `.ppif` parser/report metadata slice for the selected
`auto-id-lifecycle` contract, with static validation and no generated `.isf`,
`.fsm`, or HDL behavior changes.
