---
id: ial2-apb-data16-generalized-multi-peripheral-multi-register-six-register-contract-selection
title: APB data16 generalized six-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.687?"
  - "which APB data16 six-register generalized public sources are selected?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.688 implement?"
  - "which APB data16 six-register contract was selected?"
date: 2026-06-28
status: current
tags: [ial2, apb, contract, timing, multi-peripheral, multi-register, data16, cardinality, task-tree]
evidence: docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md; docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.687|IAL2-FEATURE-COMPLETENESS-FRONTIER\.688|data16_generalized_six_register_status_back_to_back|maximum_count = 6|reg0/reg1/reg2/reg3/reg4/reg5|0/2/4/6/8/10|No parser, generator, public source' docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.687` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.688`, direct implementation of the bounded
APB sideband-aware data16 no-policy six-register generalized `reg0..regN`
register-set multi-peripheral timing contract.

The selected public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.apb`

The implementation may widen only the selected data16 no-policy generalized
two-peripheral family from `maximum_count = 5` to `maximum_count = 6`. The
public representative uses 16-bit data, `PSTRB width 2`, status/control
windows at `0` and `258`, and `reg0/reg1/reg2/reg3/reg4/reg5` local addresses
`0/2/4/6/8/10`. Protected six-register, more-than-six-register,
more-than-two-peripheral, direct-backend, verification-output,
backend-language variant, AXI, AHB, and VHDL behavior remain deferred.
