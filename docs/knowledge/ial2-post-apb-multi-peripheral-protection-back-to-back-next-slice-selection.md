---
id: ial2-post-apb-multi-peripheral-protection-back-to-back-next-slice-selection
title: APB no-policy multi-peripheral multi-register timing readiness follows protected timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.639?"
  - "what APB timing owner follows protected multi-peripheral back-to-back behavior?"
  - "why select APB no-policy multi-peripheral multi-register timing readiness next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.640 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, multi-peripheral, multi-register, no-policy, back-to-back, readiness, task-tree]
evidence: docs/IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.639|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.640|no-policy multi-peripheral multi-register|supports only one-register peripheral completer storage|apb_additional_back_to_back_policies_deferred' docs/IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.639` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.640`, a readiness audit for APB
no-policy multi-peripheral multi-register back-to-back timing.

This is the next owner after `.638` because selected fixed no-policy
multi-register timing is shipped, selected multi-peripheral no-policy timing
is shipped for one-register peripheral shapes, and selected protected
multi-peripheral timing is shipped for the separate status/control
two-register shape. The remaining no-policy gap is the multi-peripheral
composition with two-register no-policy peripheral storage.

`.640` must not implement behavior. It must decide whether one bounded
no-policy multi-peripheral multi-register family can be implemented directly,
whether a public contract/source-shape prerequisite is needed first, or
whether the family should defer explicitly. Deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policy, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.
