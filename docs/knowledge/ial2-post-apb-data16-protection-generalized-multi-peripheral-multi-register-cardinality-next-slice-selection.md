---
id: ial2-post-apb-data16-protection-generalized-multi-peripheral-multi-register-cardinality-next-slice-selection
title: Post APB data16 protected five-register selector chooses broader cardinality audit
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.682?"
  - "what follows APB data16 protected five-register timing?"
  - "which APB owner follows the four five-register generalized siblings?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.683 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, data16, protection, cardinality, selector, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_DATA16_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.682|IAL2-FEATURE-COMPLETENESS-FRONTIER\.683|broader APB generalized register-set cardinality|more-than-five|more-than-two|four five-register siblings|No behavior changed' docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.682` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.683`, a readiness audit for broader APB
generalized register-set cardinality beyond the selected five-register,
two-peripheral timing families.

The selector changes no behavior. `.683` must re-baseline the shipped 32-bit
no-policy, data16 no-policy, 32-bit protected, and data16 protected
five-register siblings; read the current `ApbCompleter` and `ApbComposition`
cardinality/peripheral-count guards and residue; then decide whether the next
exact owner is more-than-five registers, more-than-two peripheral completers,
a smaller report/static diagnostic/address-map/public-fixture prerequisite, or
explicit deferral.

More-than-five registers, more-than-two peripheral completers, deeper queues,
alternate overflow, accepted-less timing, multiple active transfers,
alternate access policies, interconnect-owned protection policy, bus matrices,
scoreboards, direct backend behavior, verification-output generation,
backend-language variants, AXI, AHB, and VHDL remain deferred.
