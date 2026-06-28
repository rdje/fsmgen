---
id: ial2-apb-generalized-multi-peripheral-multi-register-source-shape-contract-selection
title: APB generalized multi-peripheral multi-register source-shape contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.659?"
  - "what APB generalized multi-register source-shape contract was selected?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.660 implement?"
  - "what is the bounded APB generalized register-set contract?"
date: 2026-06-28
status: current
tags: [ial2, apb, source-shape, timing, multi-peripheral, multi-register, contract, task-tree]
evidence: docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_READINESS_AUDIT.md; docs/IAL2_APB_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_TIMING_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.659|IAL2-FEATURE-COMPLETENESS-FRONTIER\.660|apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back|bounded generalized APB multi-peripheral multi-register|reg0..regN|two to four registers' docs/IAL2_APB_GENERALIZED_MULTI_PERIPHERAL_MULTI_REGISTER_SOURCE_SHAPE_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.659` selects `.660`, direct
implementation of the first bounded generalized APB multi-peripheral
multi-register source-shape family.

The selected contract adds exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
and its `.apb` profile alias. The behavior remains bounded to 32-bit
sideband-aware APB, one requester, exactly two peripheral completers, no
register-local access policies, matching source-ordered `reg0..regN`
register sets, two to four registers per peripheral, status/control windows
at `0` and `256`, depth-1 queued requester timing, adjacent setup on every
peripheral, overflow `reject`, and propagation-only interconnect decode.
Data16 generalized register sets, protected generalized register sets, more
than four registers, more than two peripherals, deeper queues, alternate
overflow, accepted-less requesters, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
