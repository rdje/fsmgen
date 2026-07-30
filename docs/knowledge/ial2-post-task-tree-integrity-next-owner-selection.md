---
id: ial2-post-task-tree-integrity-next-owner-selection
title: Post-integrity priority is the HIAL/VIAL architecture audit
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.844 select?"
  - "what follows the live task-tree integrity repair?"
  - "is the HIAL VIAL architecture selected now?"
  - "why does HIAL VIAL precede the public host-language builder?"
  - "why does HIAL VIAL precede large-design scalability?"
date: 2026-07-31
status: current
tags: [ial2, selector, hial, vial, verification, architecture, task-tree]
evidence: docs/IAL2_POST_TASK_TREE_INTEGRITY_NEXT_OWNER_SELECTION.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/knowledge/hial-vial-verification-fixture-architecture.md; docs/tasks/IAL2-HOST-LANGUAGE-BUILDER-FRONTIER.md; docs/tasks/FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY.md; docs/tasks/SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON.md; docs/decisions/0031-source-hir-remains-a-private-validated-architecture-boundary.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: scripts/check_task_tree_integrity.pl && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.844|HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE\.1|selected|remains proposed|director' docs/IAL2_POST_TASK_TREE_INTEGRITY_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/TASK_TREE.md
---

Parent selector `.844` selects proposed no-product-behavior
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`. The director-established
peer-intent architecture has a concrete verification-generation gap and AHB
fixture, no blocker, and a bounded documentation-only first audit.

The public builder remains a separate future producer/projection choice under
decision `0031`; whole-product scale retains its independent workload and
measurement contract; MCP write retains its trust boundary. Clean selector
commit `031b21d4f` activates only the selected audit through a separate
continuity transition. The architecture audit remains unperformed and product
behavior is unchanged during activation.
