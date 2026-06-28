---
id: ial2-post-apb-sideband-multi-peripheral-back-to-back-next-slice-selection
title: APB data16/protection back-to-back readiness follows sideband multi-peripheral timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.619?"
  - "what comes after APB sideband multi-peripheral back-to-back behavior?"
  - "which task owns APB data16/protection back-to-back readiness?"
  - "why choose APB data16/protection back-to-back readiness after .618?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, sideband, back-to-back, selector, task-tree]
evidence: docs/IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.619|IAL2-FEATURE-COMPLETENESS-FRONTIER\.620|data16/protection back-to-back|apb_back_to_back_policy_deferred|selected 32-bit sideband-aware multi-peripheral' docs/IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.619` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.620`, an APB data16/protection
back-to-back timing-policy readiness audit, after `.618` shipped selected
32-bit sideband-aware multi-peripheral status back-to-back propagation.

The selector changes no behavior.

Live report probes showed representative data16, protection, and
data16-protection APB requester/composition sources still report no
`back_to_back_policy` and keep `apb_back_to_back_policy_deferred`.

The current timing-policy guards are still bounded to 32-bit no-sideband or
selected 32-bit sideband-aware one-register families. Data16/protection timing
therefore needs a readiness audit before behavior because it crosses requester
queue payload widths, adjacent setup admission, multi-register storage,
protection denied-access behavior, composition/interconnect propagation,
reports, support accounting, diagnostics, validation, and rollback.

Queue-depth broadening, alternate overflow, accepted-less requesters, multiple
active APB transfers, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
