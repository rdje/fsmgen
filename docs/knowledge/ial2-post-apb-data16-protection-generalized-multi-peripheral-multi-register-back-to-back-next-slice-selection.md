---
id: ial2-post-apb-data16-protection-generalized-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: Post APB data16 protected generalized multi-peripheral next slice selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.669?"
  - "what follows APB data16 protected generalized multi-peripheral multi-register timing?"
  - "which APB residue owner follows .668?"
  - "why is broader APB register cardinality next?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, source-shape, timing, multi-peripheral, multi-register, selector, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.669|IAL2-FEATURE-COMPLETENESS-FRONTIER\.670|broader APB generalized register-set cardinality|maximum_count = 4|broader cardinality|two-to-four-register|No parser, generator, public source' docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.669` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.670`, readiness audit for broader APB
generalized register-set cardinality beyond the selected two-to-four-register
families.

The selector changes no parser, generator, public source, support-accounting,
schedule/check/semantic JSON, generated-artifact, HDL/runtime, APB, AXI, AHB,
or VHDL behavior.

The reason is that `.668` completes the selected two-peripheral generalized
register-set matrix for 32-bit and data16 widths, with and without selected
protection. The live `ApbCompleter` and `ApbComposition` guards still cap the
generalized families at `maximum_count = 4` and exactly two peripheral
completers, while live residue now names broader cardinality beyond the
selected bounded families as future work. `.670` must audit whether the next
exact owner should be a first bounded cardinality widening, a smaller
diagnostic/report/source-shape prerequisite, a more-than-two-peripheral owner,
or explicit deferral.
