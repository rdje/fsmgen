---
id: ial2-post-apb-protection-generalized-multi-peripheral-multi-register-cardinality-next-slice-selection
title: Post APB protected generalized five-register selector chooses data16 protected contract
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.679?"
  - "what follows APB 32-bit protected five-register timing?"
  - "which APB data16 protected five-register contract is selected next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.680 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, data16, protection, cardinality, selector, task-tree]
evidence: docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.679|IAL2-FEATURE-COMPLETENESS-FRONTIER\.680|data16 protected five-register|data16_protection_generalized_five_register|0/2/4/6/8|PSTRB width 2|No behavior changed' docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.679` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.680`, public contract selection for the
bounded APB sideband-aware data16 protected five-register generalized
`reg0..regN` register-set multi-peripheral timing family.

The selector changes no behavior. `.680` must settle the public `.ppif` and
`.apb` source names, object id, source anchor, data16 `PPROT`/`PSTRB`
contract, status/control windows `0` and `258`, representative local
addresses `0/2/4/6/8`, admitted-family `maximum_count = 5`, protected
access-policy matrix, support identities, report shape, diagnostics,
validation, rollback, docs, Knowledge Map, and implementation owner before
any data16 protected five-register behavior change.

More-than-five registers, more-than-two peripheral completers, deeper queues,
alternate overflow, accepted-less timing, multiple active transfers,
alternate access policies, interconnect-owned protection policy, bus matrices,
scoreboards, direct backend behavior, verification-output generation,
backend-language variants, AXI, AHB, and VHDL remain deferred.
