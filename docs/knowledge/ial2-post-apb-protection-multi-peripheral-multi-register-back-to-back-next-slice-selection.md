---
id: ial2-post-apb-protection-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: APB generalized multi-peripheral multi-register readiness selected next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.657?"
  - "what APB owner follows 32-bit protection multi-peripheral multi-register timing?"
  - "why select APB generalized multi-peripheral multi-register readiness next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.658 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, sideband, multi-peripheral, multi-register, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.657|IAL2-FEATURE-COMPLETENESS-FRONTIER\.658|generalized APB multi-peripheral multi-register|generalized multi-peripheral multi-register timing|apb_additional_back_to_back_policies_deferred' docs/IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.657` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.658`, a readiness audit for generalized
APB multi-peripheral multi-register source shapes after the selected 16/32-bit
no-policy, protection, and status/control timing families shipped.

The next owner is an audit because `.656` closed the explicit selected 32-bit
protected `reg0`/`reg1` multi-peripheral multi-register family, while earlier
slices already ship selected 32-bit/data16 no-policy `reg0`/`reg1`, data16
protected `reg0`/`reg1`, and 32-bit/data16 status/control protected timing.
The narrowed live residue now names generalized multi-peripheral
multi-register timing before deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, bus matrices, scoreboards, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL.

`.658` must decide whether the next exact owner is public contract selection
for one bounded generalized source-shape family, a smaller source-shape or
report-static prerequisite, or explicit deferral. It must not implement
generalized behavior before the public rule boundary for register counts,
names, addresses, reset values, policy matrices, and peripheral counts is
settled.
