---
id: ial2-apb-protection-generalized-multi-peripheral-multi-register-cardinality-behavior
title: APB protected generalized five-register timing shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.678?"
  - "does APB protected generalized multi-peripheral timing support five registers?"
  - "which APB protected five-register generalized sources are supported?"
  - "what remains deferred after APB protected five-register generalized timing shipped?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, protection, cardinality, behavior, task-tree]
evidence: docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.678|protection_generalized_five_register_status_back_to_back|two, three, four, or five|reg0, reg1, reg2, reg3, reg4|maximum_count = 5|PPROT\[0\] == 1' docs/IAL2_APB_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.678` ships the bounded APB
sideband-aware 32-bit protected five-register generalized `reg0..regN`
register-set multi-peripheral back-to-back timing behavior.

The shipped public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.apb`

The accepted 32-bit protected two-peripheral generalized family now admits
two, three, four, or five source-ordered registers with local addresses
`0/4/8/12/16` for the public five-register representative. The implementation
preserves 32-bit data, `PPROT width 3`, `PSTRB width 4`, status/control
windows at `0` and `256`, queue-depth `1`, overflow `reject`, adjacent setup,
the selected register-local privileged `PPROT[0] == 1` policy matrix,
propagation-only interconnect decode, and peripheral-owned protection
enforcement.

Data16 protected five-register families, more than five registers, more than
two peripheral completers, deeper queues, alternate overflow, accepted-less
timing, multiple active transfers, alternate access policies,
interconnect-owned protection policy, bus matrices, scoreboards, direct
backend behavior, verification-output generation, backend-language variants,
AXI, AHB, and VHDL remain deferred.
