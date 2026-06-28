---
id: ial2-apb-generalized-multi-peripheral-multi-register-cardinality-contract-selection
title: APB generalized multi-peripheral five-register contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.671?"
  - "which APB five-register contract was selected?"
  - "what public sources will implement APB five-register generalized cardinality?"
  - "what remains deferred after IAL2-FEATURE-COMPLETENESS-FRONTIER.671?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, cardinality, contract, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.671|IAL2-FEATURE-COMPLETENESS-FRONTIER\.672|generalized_five_register_status_back_to_back|maximum_count = 5|reg0/reg1/reg2/reg3/reg4|0/4/8/12/16|No parser, generator, public source' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.671` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.672`, direct implementation of the first
bounded APB sideband-aware 32-bit no-policy five-register generalized
`reg0..regN` register-set multi-peripheral public contract.

The selected public sources are:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.apb`

The selected family widens only the already shipped 32-bit sideband-aware
no-policy two-peripheral generalized family from `maximum_count = 4` to
`maximum_count = 5`. The public representative uses `reg0/reg1/reg2/reg3/reg4`
at local addresses `0/4/8/12/16`, 32-bit data, `PPROT width 3`,
`PSTRB width 4`, status/control windows at `0` and `256`, queue-depth `1`,
overflow `reject`, adjacent setup, no register-local `access-policy`, and a
propagation-only interconnect.

Data16 five-register families, protected five-register families, more than
five registers, more than two peripheral completers, deeper queues, alternate
overflow, accepted-less timing, multiple active transfers, bus matrices,
scoreboards, direct backend behavior, verification-output generation,
backend-language variants, AXI, AHB, and VHDL remain deferred.

This selector changes no parser, generator, public source,
support-accounting, schedule/check/semantic JSON, generated artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior.
