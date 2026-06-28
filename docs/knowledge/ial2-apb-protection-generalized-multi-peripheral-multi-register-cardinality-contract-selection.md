---
id: ial2-apb-protection-generalized-multi-peripheral-multi-register-cardinality-contract-selection
title: APB protected generalized five-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.677?"
  - "which APB protected five-register generalized sources will be implemented?"
  - "what public contract selected APB protected five-register generalized cardinality?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.678 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, task-tree, contract, cardinality, protection, multi-peripheral, multi-register]
evidence: docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.677|IAL2-FEATURE-COMPLETENESS-FRONTIER\.678|protection_generalized_five_register_status_back_to_back|maximum_count = 5|0/4/8/12/16|PPROT\[0\] == 1|No parser, generator, public source' docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.677` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.678`, direct implementation of exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`

The selected contract widens only the bounded APB sideband-aware 32-bit
protected generalized two-peripheral `reg0..regN` family from
`maximum_count = 4` to `maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/4/8/12/16`, 32-bit data,
`PPROT width 3`, `PSTRB width 4`, status/control windows `0` and `256`,
queue-depth `1`, overflow `reject`, adjacent setup, propagation-only
interconnect decode, and peripheral-owned register-local protection.

The protected policy matrix keeps `reg0` reads allowed, requires privileged
`PPROT[0] == 1` for `reg0` writes, and requires privileged `PPROT[0] == 1`
for every `reg1..regN` read/write. Data16 protected five-register register
sets, more than five registers, more than two peripherals, broader policies,
direct backend behavior, verification-output generation, backend-language
variants, AXI, AHB, and VHDL remain deferred.
