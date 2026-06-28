---
id: ial2-apb-generalized-multi-peripheral-multi-register-six-register-contract-selection
title: APB six-register generalized no-policy contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.684 select?"
  - "which APB six-register generalized no-policy public sources are selected?"
  - "what is the APB six-register generalized register-set contract?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.685?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, cardinality, contract, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BROADER_CARDINALITY_READINESS_AUDIT.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.684|IAL2-FEATURE-COMPLETENESS-FRONTIER\.685|apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back|reg0/reg1/reg2/reg3/reg4/reg5|0/4/8/12/16/20|maximum_count = 6|more than six|intent\.ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SIX_REGISTER_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.684` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.685`, direct implementation of the
bounded APB sideband-aware 32-bit no-policy six-register generalized
`reg0..regN` register-set multi-peripheral timing family.

The selected public source pair is
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif`
and the byte-identical `.apb` alias with the same stem. The selected source
uses exactly two peripheral completers, status/control windows at `0` and
`256`, `PPROT width 3`, `PSTRB width 4`, no register-local `access-policy`,
and `reg0/reg1/reg2/reg3/reg4/reg5` at local addresses `0/4/8/12/16/20`.

The implementation owner may widen only the 32-bit no-policy generalized
family from `maximum_count = 5` to `maximum_count = 6`; data16
six-register, protected six-register, more than six registers,
more-than-two peripheral completers, deeper queues, alternate overflow,
accepted-less timing, multiple active transfers, bus matrices, scoreboards,
direct backend behavior, verification-output generation, backend-language
variants, AXI, AHB, and VHDL remain deferred.
