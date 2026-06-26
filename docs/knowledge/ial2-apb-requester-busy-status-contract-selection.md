---
id: ial2-apb-requester-busy-status-contract-selection
title: APB requester busy/status contract selects additive busy-only variants
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.571 select?"
  - "what is the APB requester busy/status contract?"
  - "which APB busy sample paths are selected?"
  - "does APB requester busy/status change existing samples?"
  - "is APB status enum selected with busy?"
date: 2026-06-27
status: current
tags: [ial2, apb, requester, busy, status, task-tree]
evidence: docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_ALIAS_WIDENING_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md; docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md; fsm/apb_requester.fsm; fsm/apb_tb.fsm; ppif/apb_requester_transfer.ppif; ppif/apb_requester_transfer.apb; ppif/apb_composition.ppif; ppif/apb_composition.apb; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.571|apb_requester_transfer_busy|apb_composition_busy|apb_requester_status_field_deferred|apb_requester_busy_status_deferred|busy' docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md fsm/apb_requester.fsm fsm/apb_tb.fsm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.571` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.572`, direct bounded implementation of
additive busy-only APB requester status exposure for generated requester and
fixed composition IAL2 sources.

The selected first widening adds optional `(busy busy)` inside the APB
requester `(response ...)` block. Existing shipped APB requester and
composition samples remain unchanged; new busy-capable samples are selected at
`ppif/apb_requester_transfer_busy.ppif`,
`ppif/apb_requester_transfer_busy.apb`, `ppif/apb_composition_busy.ppif`, and
`ppif/apb_composition_busy.apb`.

The first busy slice does not select a named status enum or status-code field.
Busy-capable reports should remove `apb_requester_busy_status_deferred` and
keep the narrower `apb_requester_status_field_deferred` residue. Existing
no-busy samples keep their current residue until a future owner decides
whether to migrate or retire them.
