---
id: ial2-post-apb-sideband-composition-back-to-back-next-slice-selection
title: APB sideband multi-peripheral back-to-back contract selection chosen after fixed composition
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.616?"
  - "what APB back-to-back owner follows sideband fixed composition?"
  - "why is APB sideband multi-peripheral back-to-back next after .615?"
  - "what currently blocks APB sideband multi-peripheral back-to-back timing propagation?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-peripheral, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.616|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.617|APB multi-peripheral selected back-to-back timing-policy supports only 32-bit no-sideband|apb_composition_multi_peripheral_sideband" docs/IAL2_POST_APB_SIDEBAND_COMPOSITION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.616` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.617`, public contract selection for the
bounded 32-bit sideband-aware APB multi-peripheral back-to-back family, after
`.615` shipped sideband adjacent completer setup and fixed-composition
propagation.

Sideband multi-peripheral timing propagation is next because the required
pieces now exist separately: `.609` shipped no-sideband multi-peripheral
back-to-back propagation, `.612` shipped queued requester `PPROT/PSTRB`, and
`.615` shipped sideband adjacent completer setup plus fixed-composition
propagation.

Current sideband multi-peripheral samples already propagate `PPROT/PSTRB`
through the generated interconnect, but reports still carry broad
`apb_back_to_back_policy_deferred`. A temporary combined sideband
multi-peripheral timing-policy candidate failed exactly at the current guard
that supports only 32-bit no-sideband APB wiring for selected multi-peripheral
back-to-back timing.

Data16/protection variants, multi-register timing policy, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred.
