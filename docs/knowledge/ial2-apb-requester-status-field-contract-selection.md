---
id: ial2-apb-requester-status-field-contract-selection
title: APB requester status-field contract selects bounded 2-bit status codes
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.576 select?"
  - "what is the APB requester status-field contract?"
  - "what status code encoding is selected for APB requester status?"
  - "which APB status sample paths are selected?"
  - "does APB requester status change existing APB samples?"
  - "is an APB status enum selected?"
date: 2026-06-27
status: current
tags: [ial2, apb, requester, status-field, task-tree]
evidence: docs/IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_PUBLIC_SYNC_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md; docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.576|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.577|apb_requester_transfer_status|apb_composition_status|status status width 2|0 idle|1 busy|2 done_ok|3 done_error|apb_requester_status_field_deferred' docs/IAL2_APB_REQUESTER_STATUS_FIELD_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.576` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.577`, direct bounded implementation of an
additive APB requester named status-field contract.

The selected source shape extends the busy-capable APB requester response
block with `(status status width 2)`. In the first implementation, status is
accepted only with `(busy busy)` in the same response block.

The selected 2-bit code is `0 idle`, `1 busy`, `2 done_ok`, and
`3 done_error`. This is not a public enum declaration, custom encoding, or
sticky status register.

The selected new samples are `ppif/apb_requester_transfer_status.ppif`,
`ppif/apb_requester_transfer_status.apb`,
`ppif/apb_composition_status.ppif`, and
`ppif/apb_composition_status.apb`. Existing no-busy and busy-only APB samples
remain unchanged; no-busy samples keep `apb_requester_busy_status_deferred`,
and busy-only samples keep `apb_requester_status_field_deferred`.
