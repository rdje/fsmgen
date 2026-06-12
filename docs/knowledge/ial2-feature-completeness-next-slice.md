---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI transaction-envelope readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.11|transaction-envelope|transaction envelope|readiness audit|machine-readable|AST/structural|capacity/status|ID-family' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready, bundle, capacity/status, and ID-family metadata
IAL2 surfaces, `IAL2-FEATURE-COMPLETENESS-FRONTIER.10` selected the next
feature-completeness subset: AXI manager machine-readable AST/structural
logical read/write transaction envelope and static validation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.11` is the active next leaf. It is a
readiness audit, not a behavior implementation. It must decide whether the
transaction-envelope implementation extends `manager-capacity-status`,
introduces a broader manager object, or requires an IAL1/IAL0/SV prerequisite
first.

The full AXI manager is not implemented yet. ID allocation, ordering, response
matching, bursts, queued/blocking policy, `.pif`/`.ppi`/`.axi` aliases, and
VHDL remain future exact-owner work; they should not jump ahead of the
transaction-envelope readiness audit unless a later selector records a
stronger reason.
