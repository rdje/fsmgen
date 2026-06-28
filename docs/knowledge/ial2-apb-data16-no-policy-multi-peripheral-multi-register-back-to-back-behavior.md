---
id: ial2-apb-data16-no-policy-multi-peripheral-multi-register-back-to-back-behavior
title: APB data16 no-policy multi-peripheral multi-register back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.645?"
  - "which APB data16 no-policy multi-peripheral multi-register back-to-back behavior shipped?"
  - "which APB data16 no-policy multi-peripheral multi-register back-to-back samples are supported?"
  - "what APB data16 no-policy multi-peripheral multi-register timing residue remains after .645?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, sideband, multi-peripheral, multi-register, no-policy, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.645|apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back|selected sideband-aware data16 no-policy multi-peripheral multi-register|reg0|reg1|apb_additional_back_to_back_policies_deferred' docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.645` ships the bounded APB
sideband-aware data16 no-policy multi-peripheral multi-register
back-to-back timing-policy behavior.

The supported public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb`

The selected behavior keeps the two-peripheral status/control topology,
32-bit APB addresses, 16-bit APB/register data, `PPROT width 3`, `PSTRB
width 2`, 2-byte aligned windows at `0` and `258`, and exactly no-policy
`reg0` at address `0` plus `reg1` at address `2` in both peripheral
completers. It adds requester `accepted/busy/status` depth-1 queued timing,
adjacent setup on both no-policy peripheral completers, propagation-only
interconnect queued setup decode, active-access-only unmapped completion, and
aggregate multi-peripheral `back_to_back_policy` reporting.

The selected surfaces remove broad `apb_back_to_back_policy_deferred` and
retain narrowed future timing, protection-policy-effects, and remaining-width
residue. Data16-protection generalization, generalized multi-peripheral
multi-register shapes, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
