---
id: ial2-apb-sideband-back-to-back-behavior
title: APB sideband requester back-to-back behavior queues PPROT/PSTRB
answers:
  - "does .612 ship APB sideband back-to-back requester behavior?"
  - "does APB back-to-back support PPROT and PSTRB?"
  - "how does APB sideband back-to-back queue PPROT PSTRB?"
  - "what APB sideband back-to-back samples are supported?"
  - "what remains deferred after APB sideband requester back-to-back?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, pprot, pstrb, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_requester_transfer_sideband_status_back_to_back.ppif; ppif/apb_requester_transfer_sideband_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_sideband_status_back_to_back.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_sideband_status_back_to_back.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_sideband_status_back_to_back.apb && prove -Iperl t/1470-ial2-apb-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.612` ships bounded APB sideband-aware
requester back-to-back behavior for
`ppif/apb_requester_transfer_sideband_status_back_to_back.ppif` and the
matching `.apb` profile alias.

The selected family remains 32-bit, uses `PPROT width 3` and `PSTRB width 4`,
requires `accepted/busy/status`, and reuses the `.606` depth-1 queued
overflow-reject timing-policy vocabulary.

The generated requester adds `queued_prot` and `queued_wstrb` state. A request
accepted into the queued slot stores `req_prot` and `req_wstrb`; queued relaunch
drives `PPROT` from `queued_prot` and drives `PSTRB` from `queued_wstrb` masked
by the queued write bit. Direct terminal-cycle acceptance into an empty active
slot drives the current request sidebands immediately, masking `PSTRB` by
`req_write`.

Selected reports remove the broad `apb_back_to_back_policy_deferred` residue
for the two new requester sources and retain
`apb_additional_back_to_back_policies_deferred` for remaining timing-policy
work. Fixed composition, multi-peripheral composition, completer timing-policy
propagation, data16/protection back-to-back variants, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
