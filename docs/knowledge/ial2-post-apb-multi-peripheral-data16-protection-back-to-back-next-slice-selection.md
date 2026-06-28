---
id: ial2-post-apb-multi-peripheral-data16-protection-back-to-back-next-slice-selection
title: APB multi-peripheral multi-register timing readiness follows selected data16 protection timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.635?"
  - "what APB timing owner follows multi-peripheral data16 protection back-to-back behavior?"
  - "why select APB multi-peripheral multi-register timing readiness next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.636 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, multi-peripheral, multi-register, back-to-back, readiness, task-tree]
evidence: docs/IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.635|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.636|multi-peripheral multi-register|apb_additional_back_to_back_policies_deferred|selected sideband-aware multi-peripheral data16-protection status' docs/IAL2_POST_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.635` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.636`, a readiness audit for broader APB
multi-peripheral multi-register back-to-back timing propagation.

This is the next owner after `.634` because selected fixed-composition,
no-sideband multi-peripheral, sideband multi-peripheral, and selected
multi-peripheral data16-protection status/control timing are shipped, while
`apb_additional_back_to_back_policies_deferred` still names broader
multi-peripheral multi-register timing as the first remaining composition
timing family.

`.636` must not implement behavior. It must compare shipped fixed
multi-register timing families against shipped multi-peripheral timing
families and decide whether the next exact slice can implement one public
multi-peripheral multi-register family directly, needs another prerequisite,
or should defer explicitly. Deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, broader protection policy, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
