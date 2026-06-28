---
id: ial2-apb-no-policy-multi-peripheral-multi-register-back-to-back-contract-selection
title: APB no-policy multi-peripheral multi-register back-to-back contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.641?"
  - "what APB no-policy multi-peripheral multi-register back-to-back samples should .642 implement?"
  - "what is the selected APB no-policy multi-peripheral multi-register back-to-back contract?"
  - "which APB no-policy multi-peripheral multi-register timing variants remain deferred after .641?"
date: 2026-06-28
status: current
tags: [ial2, apb, sideband, multi-peripheral, multi-register, no-policy, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.641|IAL2-FEATURE-COMPLETENESS-FRONTIER\.642|apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back|reg0|reg1|sideband data16 no-policy multi-peripheral multi-register timing' docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.641` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.642` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb`

The selected contract is a bounded 32-bit sideband-aware no-policy
multi-peripheral composition with one requester, two peripheral completers,
status/control windows at bases `0` and `256`, requester
`accepted/busy/status` depth-1 queued timing, `PPROT width 3`, `PSTRB width 4`,
and adjacent setup admission on every peripheral.

Both selected peripheral completers use exactly the existing no-policy
two-register timing shape: local registers `reg0` at byte address `0` and
`reg1` at byte address `4`, 32-bit register data, reset `0`, and no
register-local `access-policy` clauses.

Selected reports should add aggregate `back_to_back_policy` metadata for the
requester, interconnect, and both peripherals; remove broad
`apb_back_to_back_policy_deferred` residue; retain narrowed future-policy,
protection-policy-effects, and alternate-width residue; and keep the selected
multi-peripheral decode support accounted.

Sideband data16 no-policy multi-peripheral multi-register timing,
data16-protection generalization, generalized register shapes, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred.
