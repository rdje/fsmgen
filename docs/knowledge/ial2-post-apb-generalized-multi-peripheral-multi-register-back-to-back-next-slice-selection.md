---
id: ial2-post-apb-generalized-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: Post APB generalized register-set selector chooses data16 generalized timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.661?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.661 select?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.661 select?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.662 implement?"
  - "why select APB data16 generalized register-set timing next?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, source-shape, timing, multi-peripheral, multi-register, selector, task-tree]
evidence: docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.661|IAL2-FEATURE-COMPLETENESS-FRONTIER\.662|apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back|data16 no-policy generalized|reg0/reg1/reg2.*0/2/4|status/control windows at `0` and `258`|protected generalized register sets' docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.661` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.662`, direct implementation of the bounded
APB sideband-aware data16 no-policy generalized `reg0..regN` register-set
multi-peripheral back-to-back timing family.

The selected public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif`
and its `.apb` alias. The contract mirrors `.660`'s no-policy generalized
shape but uses 16-bit APB/register data, `PSTRB width 2`, 2-byte register
stride, public representative `reg0/reg1/reg2` at local addresses `0/2/4`,
and sideband data16 status/control windows at `0` and `258`.

Protected generalized register sets, broader cardinality/peripheral count,
deeper queues, alternate overflow, accepted-less requesters, multiple active
transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
