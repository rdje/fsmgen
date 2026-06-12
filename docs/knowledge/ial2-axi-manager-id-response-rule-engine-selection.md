---
id: ial2-axi-manager-id-response-rule-engine-selection
title: AXI manager ID/response rule-engine readiness is selected
answers:
  - "what comes after AXI transaction event dispatch?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.17?"
  - "is AXI ID allocation implemented now?"
  - "what must happen before AXI response matching?"
  - "why is ID response readiness next?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, id, response-matching, task-tree]
evidence: docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'ID/response rule-engine|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.17|response matching|BID|RID|id_families|transaction_event_dispatch' docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After transaction event dispatch shipped, the next selected AXI manager subset
is ID/response rule-engine readiness.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.16` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.17` as the readiness-audit owner. The audit
must decide whether the first ID/response behavior can extend the existing
`manager-capacity-status` object through current IAL1/IAL0/SystemVerilog
substrate, should be narrowed to concrete-ID validation/matching first,
requires a lower-layer prerequisite, or must be deferred behind another exact
owner.

This is not an implementation claim. ID allocation, dynamic user-ID validation,
ID release, same-ID ordering, different-ID interleaving, `BID`/`RID` response
matching, bursts, queued/blocking policy, profile aliases, full AXI manager
syntax, and VHDL remain unshipped until later exact owners implement them.
