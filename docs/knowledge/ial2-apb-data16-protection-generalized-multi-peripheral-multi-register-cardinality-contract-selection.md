---
id: ial2-apb-data16-protection-generalized-multi-peripheral-multi-register-cardinality-contract-selection
title: APB data16 protected generalized five-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.680?"
  - "what public contract selected APB data16 protected five-register generalized cardinality?"
  - "what public sources will implement APB data16 protected five-register generalized cardinality?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.681 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, data16, protection, cardinality, contract, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.680|IAL2-FEATURE-COMPLETENESS-FRONTIER\.681|data16_protection_generalized_five_register_status_back_to_back|maximum_count = 5|reg0/reg1/reg2/reg3/reg4|0/2/4/6/8|PPROT\[0\] == 1|No parser, generator, public source' docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.680` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.681` to implement exactly:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.apb`

The contract widens only the shipped data16 sideband-aware protected
two-peripheral generalized `reg0..regN` register-set family from
`maximum_count = 4` to `maximum_count = 5`. The public representative uses
`reg0/reg1/reg2/reg3/reg4` at local addresses `0/2/4/6/8`, 16-bit data,
`PPROT width 3`, `PSTRB width 2`, status/control windows `0` and `258`,
queue-depth `1`, overflow `reject`, adjacent setup, propagation-only
interconnect decode, and the selected register-local privileged `PPROT[0]`
access-policy matrix.

No parser, generator, public source, support-accounting, report, generated
artifact, HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes in
`.680`.
