---
id: ial2-post-apb-data16-generalized-multi-peripheral-multi-register-cardinality-next-slice-selection
title: Post APB data16 generalized five-register selector chooses protected five-register contract
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.676?"
  - "what APB owner follows data16 five-register no-policy timing?"
  - "which APB protected five-register contract is selected next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.677 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, task-tree, selector, cardinality, protection, multi-peripheral, multi-register]
evidence: docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.676|IAL2-FEATURE-COMPLETENESS-FRONTIER\.677|protected five-register|protection_generalized_five_register|maximum_count = 5|0/4/8/12/16|PPROT\[0\] == 1|No parser, generator, public source' docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.676` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.677`, public contract selection for the
bounded APB sideband-aware 32-bit protected five-register generalized
`reg0..regN` register-set multi-peripheral timing family.

The selector changes no behavior. `.677` must settle the public `.ppif` and
`.apb` source names, source object, anchor, 32-bit data shape, `PPROT width 3`,
`PSTRB width 4`, status/control windows `0` and `256`, local addresses
`0/4/8/12/16`, access-policy matrix, report/support identities, diagnostics,
validation, rollback, and implementation owner before any protected
five-register behavior change.

Data16 protected five-register generalized register sets, more than five
registers, more than two peripherals, deeper queues, alternate overflow,
accepted-less timing, multiple active transfers, bus matrices, scoreboards,
direct backend behavior, verification-output generation, backend-language
variants, AXI, AHB, and VHDL remain deferred.
