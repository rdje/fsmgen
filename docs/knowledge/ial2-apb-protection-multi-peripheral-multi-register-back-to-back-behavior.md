---
id: ial2-apb-protection-multi-peripheral-multi-register-back-to-back-behavior
title: APB 32-bit protection multi-peripheral multi-register back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.656?"
  - "which APB 32-bit protection multi-peripheral multi-register back-to-back behavior shipped?"
  - "which APB 32-bit protection multi-peripheral multi-register back-to-back samples are supported?"
  - "what APB protection multi-peripheral multi-register timing residue remains after .656?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, sideband, multi-peripheral, multi-register, back-to-back, behavior, task-tree]
evidence: docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.656|apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back|selected sideband-aware 32-bit protection multi-peripheral multi-register|protected reg0|protected reg1|apb_additional_back_to_back_policies_deferred' docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.656` ships the bounded APB
sideband-aware 32-bit protection multi-peripheral multi-register
back-to-back timing-policy behavior.

The supported public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb`

The selected behavior keeps the two-peripheral status/control topology,
32-bit APB addresses, 32-bit APB/register data, `PPROT width 3`, `PSTRB
width 4`, 4-byte aligned windows at `0` and `256`, and exactly protected
`reg0` at address `0` plus protected `reg1` at address `4` in both
peripheral completers. `reg0` reads are allowed and writes require
privileged `PPROT[0]`; `reg1` reads and writes require privileged
`PPROT[0]`. The requester provides `accepted/busy/status` depth-1 queued
timing, both peripherals use adjacent setup, and the interconnect propagates
queued 32-bit `PWDATA`, `PPROT`, and 4-bit `PSTRB` without enforcing
protection itself.

The selected surfaces remove broad `apb_back_to_back_policy_deferred` and
old `apb_protection_policy_effects_deferred` residue. They retain narrowed
future timing, additional-protection-policy, and alternate-width residue.
Generalized multi-peripheral multi-register shapes, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, bus
matrices, scoreboards, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
