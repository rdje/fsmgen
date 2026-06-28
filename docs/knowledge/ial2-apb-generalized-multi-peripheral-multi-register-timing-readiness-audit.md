---
id: ial2-apb-generalized-multi-peripheral-multi-register-timing-readiness-audit
title: APB generalized multi-peripheral multi-register timing readiness audited
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.654?"
  - "what APB generalized multi-peripheral multi-register timing audit found?"
  - "why select APB 32-bit protected reg0/reg1 multi-peripheral contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.655 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, timing, multi-peripheral, multi-register, protection, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md; docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.654|IAL2-FEATURE-COMPLETENESS-FRONTIER\.655|32-bit protected `reg0`/`reg1`|multi-peripheral multi-register timing|selected two-peripheral sideband protection status/control storage shape' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.654` audits generalized APB
multi-peripheral multi-register timing after the status/control
protected-storage residue cleanup.

The audit selects `.655`, public contract selection for the bounded APB
sideband-aware 32-bit protected `reg0`/`reg1` multi-peripheral
multi-register back-to-back timing family. Shipped behavior already covers
32-bit and data16 no-policy `reg0`/`reg1`, data16 protected `reg0`/`reg1`,
and 32-bit/data16 status-control protected families. A temporary 32-bit
protected `reg0`/`reg1` candidate still fails at the current
multi-peripheral timing guard, so direct implementation is not selected
before a contract slice. Broad generalized timing, deeper queues, alternate
overflow, accepted-less requesters, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
