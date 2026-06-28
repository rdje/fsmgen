---
id: ial2-apb-generalized-multi-peripheral-multi-register-six-register-behavior
title: APB generalized six-register no-policy timing shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.685?"
  - "does APB generalized no-policy multi-peripheral timing support six registers?"
  - "which APB six-register generalized sources are supported?"
  - "what remains deferred after APB six-register no-policy timing shipped?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, cardinality, behavior, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.685|generalized_six_register_status_back_to_back|two, three, four, five, or six|reg0, reg1, reg2, reg3, reg4, reg5|maximum_count = 6|IAL2-FEATURE-COMPLETENESS-FRONTIER\.686' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.685` ships the bounded APB
sideband-aware 32-bit no-policy six-register generalized `reg0..regN`
register-set multi-peripheral back-to-back timing behavior.

The shipped public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.apb`

The accepted 32-bit no-policy two-peripheral generalized family now admits
two, three, four, five, or six source-ordered registers with local addresses
`0/4/8/12/16/20` for the public six-register representative. The
implementation preserves 32-bit data, `PPROT width 3`, `PSTRB width 4`,
status/control windows at `0` and `256`, queue-depth `1`, overflow `reject`,
adjacent setup, no register-local `access-policy`, propagation-only
interconnect decode, and no interconnect protection predicate.

Data16 six-register families, protected six-register families, more than six
registers, more than two peripheral completers, deeper queues, alternate
overflow, accepted-less timing, multiple active transfers, bus matrices,
scoreboards, direct backend behavior, verification-output generation,
backend-language variants, AXI, AHB, and VHDL remain deferred.
