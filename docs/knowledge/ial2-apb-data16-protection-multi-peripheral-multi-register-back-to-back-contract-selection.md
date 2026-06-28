---
id: ial2-apb-data16-protection-multi-peripheral-multi-register-back-to-back-contract-selection
title: APB data16-protection multi-peripheral multi-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.648?"
  - "what APB data16-protection multi-peripheral multi-register contract was selected?"
  - "what APB data16-protection multi-peripheral multi-register sources should .649 implement?"
  - "which APB data16-protection multi-peripheral multi-register variants remain deferred after .648?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, multi-peripheral, multi-register, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.648|IAL2-FEATURE-COMPLETENESS-FRONTIER\.649|apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back|Selected Protected Peripheral Storage|reg0.*privileged|reg1.*privileged' docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.648` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.649` to directly implement exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected contract is one requester, two peripheral completers, 32-bit
addresses, 16-bit APB/register data, `PPROT width 3`, `PSTRB width 2`,
status/control windows at bases `0` and `258` with size `258`, adjacent setup
on both peripherals, and exactly protected `reg0` at local address `0` plus
protected `reg1` at local address `2` in each peripheral. `reg0` reads are
allowed and writes require privileged `PPROT[0]`; `reg1` reads and writes
require privileged `PPROT[0]`.

`.649` must keep status/control protected storage generalization beyond
`.634`, generalized register shapes, queue depths other than `1`, overflow
policies other than `reject`, accepted-less requesters, multiple active APB
transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL deferred.
