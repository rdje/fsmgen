---
id: ial2-apb-generalized-multi-peripheral-multi-register-cardinality-readiness-audit
title: APB generalized multi-peripheral register-set cardinality readiness audited
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.670?"
  - "which APB broader register cardinality owner was selected?"
  - "is APB generalized register-set cardinality ready for implementation?"
  - "why is APB 32-bit no-policy five-register contract selection next?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, cardinality, readiness, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md; docs/IAL2_POST_APB_DATA16_PROTECTION_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.670|IAL2-FEATURE-COMPLETENESS-FRONTIER\.671|five-register|maximum_count = 5|reg0/reg1/reg2/reg3/reg4|0/4/8/12/16|No parser, generator, public source' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_CARDINALITY_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/RegressionCorpus.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.670` audits broader APB generalized
register-set cardinality readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.671`, public contract selection for the
first bounded APB sideband-aware 32-bit no-policy five-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

The audit changes no parser, generator, public source, support-accounting,
schedule/check/semantic JSON, generated-artifact, HDL/runtime, APB, AXI, AHB,
or VHDL behavior.

The selected first widening is 32-bit no-policy because it isolates register
cardinality from data16 stride/strobe changes and protection-policy matrix
changes. `.671` must settle exact public source names, whether the admitted
family becomes `maximum_count = 5`, representative
`reg0/reg1/reg2/reg3/reg4` local addresses `0/4/8/12/16`, report/support
shape, diagnostics, validation, rollback, docs, Knowledge Map, and the next
owner before any implementation change.
