---
id: ial2-post-apb-protection-generalized-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: Post APB protected generalized selector chooses data16 protected generalized contract
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.666?"
  - "what APB owner follows protected generalized register-set timing?"
  - "why select APB data16 protected generalized register-set contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.667 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, timing, data16, protected, source-shape, multi-peripheral, multi-register, selector, task-tree]
evidence: docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.666|IAL2-FEATURE-COMPLETENESS-FRONTIER\.667|data16 protected generalized register sets|data16 protected generalized `reg0..regN`|bounded APB sideband-aware data16 protected generalized|local byte addresses `0`, `2`' docs/IAL2_POST_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.666` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.667`, public contract selection for the
bounded APB sideband-aware data16 protected generalized `reg0..regN`
register-set multi-peripheral back-to-back timing family.

The selector changes no behavior. It follows `.665` because generalized
no-policy timing is shipped for both selected widths and protected
generalized timing is shipped for 32-bit, while data16 protected generalized
register sets remain explicitly deferred by the current APB guards and
residue text.

`.667` must settle exact public source names, object id, source anchor,
16-bit APB/register data, `PSTRB width 2`, `PPROT width 3`, status/control
windows at `0` and `258`, local addresses `0/2/4/...`, protected access-policy
matrix, report shape, support accounting, diagnostics, validation, rollback,
docs, Knowledge Map, and next owner before parser/generator/sample/test/HDL
behavior changes.
