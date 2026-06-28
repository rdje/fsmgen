---
id: ial2-post-apb-data16-generalized-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: Post APB data16 generalized selector chooses protected generalized contract
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.663?"
  - "what APB owner follows data16 generalized register-set timing?"
  - "why select APB protected generalized register-set contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.664 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, timing, protected, source-shape, multi-peripheral, multi-register, selector, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.663|IAL2-FEATURE-COMPLETENESS-FRONTIER\.664|protected generalized register sets|protected generalized `reg0..regN`|bounded APB sideband-aware 32-bit protected generalized|policy matrix for every selected `reg0..regN`' docs/IAL2_POST_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.663` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.664`, public contract selection for the
bounded APB sideband-aware 32-bit protected generalized `reg0..regN`
register-set multi-peripheral back-to-back timing family.

The selector changes no behavior. It follows `.662` because no-policy
generalized register-set timing is now shipped for both selected 32-bit and
data16 widths, while protected generalized register sets still need a public
policy matrix for `reg2..regN` before any timing guard can widen safely.

`.664` must settle the exact public source names, object id, register
cardinality, local address rules, protected access-policy matrix, report shape,
support accounting, diagnostics, validation, rollback, docs, Knowledge Map,
and next owner before parser/generator/sample/test/HDL behavior changes.
