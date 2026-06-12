---
id: ial2-feature-completeness-next-slice
title: IAL2 feature completeness next slice is AXI manager ID-family readiness
answers:
  - "what is the next IAL2 feature completeness slice?"
  - "what comes after PPIF Valid-Ready bundles?"
  - "is the full AXI manager implemented after Valid-Ready?"
  - "should .axi aliases come before AXI manager rules?"
  - "what must happen before implementing AXI manager behavior?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, feature-completeness, task-tree]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md; docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_MANAGER_USER_API_BRAINSTORM.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.8|ID-family|id-families|capacity/status|readiness audit' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

After the shipped Valid-Ready and capacity/status IAL2 surfaces,
`IAL2-FEATURE-COMPLETENESS-FRONTIER.7` selected the next AXI manager subset:
ID-family declaration and static validation.

The active next feature-completeness slice is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.8`: audit implementation readiness for
that selected ID-family subset. The audit must decide whether the
implementation should be an additive capacity/status extension, a broader
manager object, or a prerequisite IAL1/IAL0/SV substrate slice before behavior
changes.

The full AXI manager is not implemented yet. ID allocation, ordering, response
matching, bursts, queued/blocking policy, `.pif`/`.ppi`/`.axi` aliases, and
VHDL remain future exact-owner work; they should not jump ahead of the
ID-family readiness path unless a later selector records a stronger reason.
