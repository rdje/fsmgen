---
id: ial2-apb-generalized-multi-peripheral-multi-register-source-shape-readiness-audit
title: APB generalized multi-peripheral multi-register source-shape readiness audited
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.658?"
  - "what APB generalized multi-peripheral multi-register source-shape audit found?"
  - "why select APB generalized multi-register contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.659 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, task-tree]
evidence: >-
  docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT.md; docs/IAL2_POST_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md;
  docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.658|IAL2-FEATURE-COMPLETENESS-FRONTIER\.659|bounded generalized APB multi-peripheral multi-register source-shape|source-shape contract|generalized multi-peripheral multi-register' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.658` audits generalized APB
multi-peripheral multi-register source-shape readiness after the selected
`reg0`/`reg1` timing families shipped.

The audit selects `.659`, public contract selection for one bounded
generalized APB multi-peripheral multi-register source-shape family. The
current implementation is intentionally exact-family guarded; broad behavior
needs public rules for register cardinality, register names, local byte
addresses, reset values, policy matrices, per-peripheral consistency,
support accounting, diagnostics, validation, and residue movement before
implementation. Direct generalized behavior, deeper queues, alternate
overflow, accepted-less requesters, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
