---
id: ial2-axi-manager-id-response-readiness-audit
title: AXI ID/response readiness selects concrete ID assertions
answers:
  - "what did the AXI ID response readiness audit conclude?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.18?"
  - "can AXI concrete ID checks be implemented now?"
  - "does AXI ID readiness require an IAL1 prerequisite?"
  - "are AXI automatic IDs allocated now?"
date: 2026-06-12
status: current
tags: [ial2, ial1, axi, manager, id, assertions, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'concrete transaction ID|concrete-ID|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.18|id_response_rule_engine|\\+assert|assertion-only|auto-ID allocation|response demux' docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.17` concluded that the first AXI
ID/response implementation should be a narrow concrete transaction ID
assertion slice.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.18` shipped that implementation. It
declares used positive-width ID-family request/response ID signals as
generated IAL1 inputs and emits assertion-only transaction checks through
`.fsm` `+assert` carriers and the existing SystemVerilog assertion backend.

No separate IAL1, IAL0, or SystemVerilog prerequisite is required for that
exact concrete-ID assertion slice.

Automatic ID allocation, ID release, same-ID ordering, different-ID
interleaving, generated response demux, bursts, queued/blocking policy,
profile aliases, full AXI manager syntax, and VHDL remain residue.
