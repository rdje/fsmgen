---
id: ial2-apb-protection-generalized-multi-peripheral-multi-register-back-to-back-contract-selection
title: APB protected generalized multi-peripheral multi-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.664?"
  - "what APB protected generalized register-set contract is selected?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.665 implement?"
  - "what is the APB protected generalized reg0..regN access-policy matrix?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, timing, multi-peripheral, multi-register, contract, task-tree]
evidence: docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.664|IAL2-FEATURE-COMPLETENESS-FRONTIER\.665|apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back|reg0` read: allow|reg2..regN|PPROT\[0\] == 1' docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.664` selects `.665`, direct
implementation of the bounded APB sideband-aware 32-bit protected generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

The selected public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif`
and its `.apb` profile alias. The contract remains bounded to one requester,
exactly two peripheral completers, 32-bit APB/register data, `PPROT width 3`,
`PSTRB width 4`, status/control windows at `0` and `256`, queue-depth `1`,
overflow `reject`, adjacent setup on every peripheral, propagation-only
interconnect decode, and matching protected `reg0..regN` register sets with
two to four registers per peripheral. The public representative uses
`reg0/reg1/reg2` at local addresses `0/4/8`.

The selected access-policy matrix is: `reg0` read allow; `reg0` write require
privileged `PPROT[0] == 1`; every `regN` where `N >= 1` read require
privileged `PPROT[0] == 1`; and every `regN` where `N >= 1` write require
privileged `PPROT[0] == 1`. Data16 protected generalized register sets,
broader cardinality/peripheral count, deeper queues, alternate overflow,
accepted-less requesters, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
