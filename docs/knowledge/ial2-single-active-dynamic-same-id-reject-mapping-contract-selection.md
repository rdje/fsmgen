---
id: ial2-single-active-dynamic-same-id-reject-mapping-contract-selection
title: Single-active dynamic same-ID reject contract selects direct mapping
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.441 select?"
  - "what report fields should single-active dynamic same-ID reject mapping use?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.442?"
  - "does single-active dynamic reject mapping reuse .438 assertion fields?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, contract]
evidence: docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_DYNAMIC_SAME_ID_REJECT_ENFORCEMENT_MAPPING_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.441|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.442|SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION|generated_single_active_reject|generated_idle_or_releasing_assertions|single_active_request_policy' docs/AXI_IAL2_MANAGER_SINGLE_ACTIVE_DYNAMIC_SAME_ID_REJECT_MAPPING_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.441` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.442`, direct implementation of
single-active dynamic same-ID reject report/acceptance mapping.

The selected report contract uses `implementation_status:
generated_single_active_reject`, `enforcement:
generated_idle_or_releasing_assertions`, `single_active_covered: true`, and
`single_active_request_policy: idle_or_releasing`.

It intentionally does not reuse the `.438` multi-active
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions` fields, because single-active
families do not generate those sibling-comparison assertions.
