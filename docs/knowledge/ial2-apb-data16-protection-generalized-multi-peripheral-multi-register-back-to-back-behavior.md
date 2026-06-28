---
id: ial2-apb-data16-protection-generalized-multi-peripheral-multi-register-back-to-back-behavior
title: APB data16 protected generalized multi-peripheral multi-register back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.668?"
  - "which APB data16 protected generalized multi-peripheral multi-register behavior shipped?"
  - "which APB data16 protected generalized register-set samples are supported?"
  - "what APB data16 protected generalized register-set residue remains after .668?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, source-shape, timing, multi-peripheral, multi-register, behavior, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.668|IAL2-FEATURE-COMPLETENESS-FRONTIER\.669|apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back|sideband-aware data16 protected generalized|PPROT\[0\] == 1|0/2/4|peripheral-owned protection' docs/IAL2_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.668` ships the bounded APB
sideband-aware data16 protected generalized `reg0..regN` register-set
multi-peripheral back-to-back timing behavior.

The supported public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
and its `.apb` alias. They use one requester, exactly two peripheral
completers, 16-bit APB/register data, `PPROT width 3`, `PSTRB width 2`,
status/control windows at `0` and `258`, depth-1 queued requester timing,
adjacent setup on every peripheral, overflow `reject`, propagation-only
interconnect decode, and peripheral-owned protection enforcement. The public
representative proves the generalized shape with `reg0/reg1/reg2` at local
addresses `0/2/4`; the admitted family remains bounded to matching protected
`reg0..regN` register sets with two to four registers per peripheral.

The selected policy matrix is: `reg0` read allow; `reg0` write require
privileged `PPROT[0] == 1`; every `regN` where `N >= 1` read require
privileged `PPROT[0] == 1`; and every `regN` where `N >= 1` write require
privileged `PPROT[0] == 1`. Broader cardinality/peripheral count, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, bus matrices, scoreboards, alternate protection-policy matrices,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred. `.669` owns the next APB timing/register-set residue
selector.
