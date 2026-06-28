---
id: ial2-apb-sideband-back-to-back-readiness-audit
title: APB sideband back-to-back audit selects requester-first implementation
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.611?"
  - "is APB sideband back-to-back ready to implement?"
  - "what APB sideband back-to-back owner comes after .611?"
  - "why is APB sideband back-to-back split requester first?"
  - "what should .612 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.611|apb_requester_transfer_sideband_status_back_to_back|queued_prot|queued_wstrb|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.612" docs/IAL2_APB_SIDEBAND_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.611` audits APB sideband-aware
back-to-back timing-policy readiness after selected no-sideband fixed and
multi-peripheral back-to-back behavior shipped.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.612`, a narrow
requester-first implementation. `.612` should add only
`ppif/apb_requester_transfer_sideband_status_back_to_back.ppif` and the
matching `.apb` profile alias, with 32-bit data, `PPROT width 3`,
`PSTRB width 4`, `accepted/busy/status`, and the existing depth-1 queued
overflow-reject timing-policy vocabulary.

No new public timing-policy vocabulary is needed. `.606` already selected
that accepted requests sample all request payload fields at acceptance time,
including sidebands when present.

The split is intentional. The current generated requester queue stores only
`queued_addr`, `queued_write`, and `queued_wdata`; a sideband candidate fails
at the existing no-sideband requester timing-policy guard. `.612` must first
add queued `PPROT/PSTRB` storage and relaunch behavior through `queued_prot`
and `queued_wstrb`. Fixed composition, multi-peripheral composition,
completer timing-policy propagation, data16/protection variants, deeper
queues, alternate overflow, accepted-less requester surfaces, multiple active
APB transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
