---
id: ial2-post-apb-generalized-multi-peripheral-multi-register-six-register-next-slice-selection
title: APB data16 six-register contract selected next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.686?"
  - "what comes after APB six-register no-policy timing?"
  - "which APB six-register residue is selected next?"
  - "is APB data16 six-register generalized behavior implemented?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, data16, cardinality, selector, task-tree]
evidence: docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.686|IAL2-FEATURE-COMPLETENESS-FRONTIER\.687|data16 no-policy six-register|0/2/4/6/8/10|PSTRB width 2|No parser, generator, public source' docs/IAL2_POST_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.686` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.687`, public contract selection for the
bounded APB sideband-aware data16 no-policy six-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

The selected next owner must settle exact public `.ppif`/`.apb` source names,
source object metadata, one-requester/two-peripheral scope, 16-bit data,
`PPROT width 3`, `PSTRB width 2`, status/control windows at `0` and `258`,
representative local addresses `0/2/4/6/8/10`, no register-local
`access-policy`, queue-depth `1`, overflow `reject`, adjacent setup,
propagation-only interconnect decode, support/report identities, diagnostics,
validation, rollback, docs, Knowledge Map, and next owner before behavior
changes.

This selector implements no data16 six-register behavior. Protected
six-register families, more than six registers, more than two peripheral
completers, deeper queues, alternate overflow, accepted-less timing, multiple
active transfers, bus matrices, scoreboards, direct backend behavior,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
remain deferred.
