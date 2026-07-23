---
id: ial2-post-current-surface-repair-next-owner-selection
title: Post-current-surface selection chooses the AHB boundary-free active-transfer audit
answers:
  - "what follows the AHB current-surface alias truthfulness repair?"
  - "which AHB task is selected after IAL2-FEATURE-COMPLETENESS-FRONTIER.806?"
  - "why is boundary-free AHB active-transfer pipelining audited next?"
  - "does the current AHB subordinate accept consecutive active address phases?"
  - "does IAL2-FEATURE-COMPLETENESS-FRONTIER.807 activate the pipeline audit?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, pipeline, phase, audit, selection]
evidence: docs/IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/knowledge/ial2-ahb-paired-busy-composition-behavior.md; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1515-ial2-ahb-two-subordinate-paired-busy-composition.t; t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'ahb_access_active_q|ahb_access_admit|ahb_access_release|continue-when|drive transfer_nonseq|drive transfer_seq' perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm t/1513-ial2-ahb-paired-busy-composition.t && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.807|IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT' docs/IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md docs/TASK_TREE.md MEMORY.md
---

After `.806` repaired current AHB alias truth, `.807` selects the existing
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT`. Current subordinate ownership
admits only when `ahb_access_active_q` is clear and releases only on
unselected/IDLE/BUSY boundaries. The shipped paired requester supplies such a
boundary, so t/1513/t1515 do not prove direct active-to-active replacement.

The selected audit must use generated public subordinate HDL to distinguish a
held address phase from a new consecutive active address phase and record
acceptance, data-phase response, ownership, and storage exactly once. It makes
no behavior change; any repair or fail-closed contract requires a separate
runtime-evidence-backed leaf. `.807` does not activate the audit until it
commits cleanly. Decision 0020 remains proposed/inactive.
