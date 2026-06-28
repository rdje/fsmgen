---
id: ial2-apb-sideband-multi-peripheral-back-to-back-contract-selection
title: APB sideband multi-peripheral back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.617?"
  - "what APB sideband multi-peripheral back-to-back samples should .618 implement?"
  - "what is the selected APB sideband multi-peripheral back-to-back contract?"
  - "which APB back-to-back timing variants remain deferred after .617?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-peripheral, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.617|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.618|apb_composition_multi_peripheral_sideband_status_back_to_back|sideband-aware variant of" docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.617` selects the public contract for the
bounded 32-bit sideband-aware APB multi-peripheral back-to-back family.

`.618` should implement exactly two public sources:

- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb`

The selected contract is a two-peripheral 32-bit sideband-aware composition
with requester `accepted/busy/status`, depth-1 queued requester timing policy,
`PPROT width 3`, `PSTRB width 4`, adjacent setup admission on every one-register
peripheral completer, and the existing static non-overlapping status/control
address-map/decode shape.

The selected implementation should remove broad
`apb_back_to_back_policy_deferred` for the selected top, requester,
interconnect, and peripheral report surfaces while retaining narrowed future
back-to-back residue and the existing protection-policy effects residue.

Data16/protection back-to-back variants, multi-register timing policy, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, multi-requester interconnects, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
