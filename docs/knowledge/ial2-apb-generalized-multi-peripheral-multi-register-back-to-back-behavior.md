---
id: ial2-apb-generalized-multi-peripheral-multi-register-back-to-back-behavior
title: APB generalized multi-peripheral multi-register back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.660?"
  - "which APB generalized multi-peripheral multi-register behavior shipped?"
  - "which APB generalized register-set samples are supported?"
  - "what APB generalized register-set residue remains after .660?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, behavior, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.660|IAL2-FEATURE-COMPLETENESS-FRONTIER\.661|apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back|selected bounded sideband-aware generalized no-policy|reg0..regN register-set' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.660` ships the first bounded generalized
APB sideband-aware no-policy multi-peripheral multi-register register-set
behavior.

The supported public sources are
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
and its `.apb` alias. They use one requester, exactly two peripheral
completers, 32-bit APB/register data, `PPROT width 3`, `PSTRB width 4`,
status/control windows at `0` and `256`, depth-1 queued requester timing,
adjacent setup on every peripheral, overflow `reject`, and propagation-only
interconnect decode. The public representative proves the generalized shape
with `reg0/reg1/reg2` at local addresses `0/4/8`; the admitted family remains
bounded to matching no-policy `reg0..regN` register sets with two to four
registers per peripheral.

Data16 generalized register sets, protected generalized register sets, more
than four registers, more than two peripherals, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, bus
matrices, scoreboards, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred. `.661` selects the next owner in
the post-generalized-register-set selector record.
