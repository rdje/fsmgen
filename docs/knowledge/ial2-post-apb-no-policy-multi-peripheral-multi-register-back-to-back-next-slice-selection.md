---
id: ial2-post-apb-no-policy-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: APB data16 no-policy multi-peripheral multi-register timing selected next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.643?"
  - "what APB owner follows no-policy multi-peripheral multi-register timing?"
  - "why select APB data16 no-policy multi-peripheral multi-register contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.644 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, no-policy, multi-peripheral, multi-register, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.643|IAL2-FEATURE-COMPLETENESS-FRONTIER\.644|sideband data16 no-policy multi-peripheral multi-register|apb_composition_multi_peripheral_sideband_data16|apb_composition_multi_register_sideband_data16_status_back_to_back|apb_additional_back_to_back_policies_deferred' docs/IAL2_POST_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.643` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.644`, public contract selection for the
bounded APB sideband-aware data16 no-policy multi-peripheral multi-register
back-to-back timing family.

The next owner is data16 no-policy multi-peripheral multi-register timing
because `.625` already ships fixed-composition data16 no-policy reg0/reg1
timing, `.634` already ships data16 multi-peripheral timing for the protected
status/control shape, and `.642` already ships 32-bit no-policy reg0/reg1
multi-peripheral timing. No public data16 no-policy multi-peripheral
multi-register back-to-back source exists yet.

`.644` must settle exact public source names, the data16 status/control window
shape, requester/completer/interconnect timing requirements, no-policy
`reg0`/`reg1` storage requirements, report/residue movement,
support-accounting identities, diagnostics, validation, rollback, and docs
before any parser, generator, sample, test, report, or HDL behavior change.
