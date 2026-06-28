---
id: ial2-apb-protection-multi-peripheral-multi-register-back-to-back-contract-selection
title: APB 32-bit protected reg0/reg1 multi-peripheral multi-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.655?"
  - "which APB 32-bit protected reg0/reg1 multi-peripheral multi-register public sources are selected?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.656 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, multi-peripheral, multi-register, back-to-back, contract, task-tree]
evidence: docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.655|IAL2-FEATURE-COMPLETENESS-FRONTIER\.656|apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back|32-bit protected `reg0`/`reg1`|multi-peripheral timing guard' docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.655` selects `.656`, direct
implementation of the bounded APB sideband-aware 32-bit protected
`reg0`/`reg1` multi-peripheral multi-register back-to-back timing contract.

The selected public source pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
and
`ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb`.
The selected family uses one requester, two peripheral completers, 32-bit
APB/register data, `PPROT width 3`, `PSTRB width 4`, status/control windows
at bases `0` and `256`, adjacent setup on both peripherals, and protected
`reg0`/`reg1` storage at local addresses `0` and `4`. Implementation remains
future work until `.656`; `.655` changes no parser, generator, public source,
support-accounting, report, HDL, APB transaction, AXI, AHB, or VHDL behavior.
