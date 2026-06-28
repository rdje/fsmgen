---
id: ial2-post-apb-data16-no-policy-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: APB data16-protection generalization readiness selected next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.646?"
  - "what APB owner follows data16 no-policy multi-peripheral multi-register timing?"
  - "why select APB data16-protection generalization readiness next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.647 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, multi-peripheral, multi-register, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.646|IAL2-FEATURE-COMPLETENESS-FRONTIER\.647|data16-protection generalization|multi_peripheral_multi_register_sideband_data16_protection|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back|apb_additional_back_to_back_policies_deferred' docs/IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.646` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.647`, a readiness audit for APB
data16-protection generalization.

The next owner is an audit because `.645` and `.642` ship selected no-policy
multi-peripheral multi-register timing for data16 and 32-bit families, while
`.634` and `.631` ship selected protected data16 timing for multi-peripheral
and fixed-composition families. No explicit public
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection`
back-to-back source exists yet, and the residue names data16-protection
generalization before broader generalized multi-peripheral multi-register
shapes.

`.647` must decide whether the next exact owner is public contract selection
for an explicit bounded data16-protection multi-peripheral multi-register
family, direct implementation of an already-selected family, a smaller
source-shape/report-static prerequisite, or explicit deferral. It must keep
generalized register shapes, queue depths other than `1`, overflow policies
other than `reject`, accepted-less requesters, multiple active APB transfers,
bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL deferred.
