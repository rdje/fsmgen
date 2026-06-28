---
id: ial2-apb-no-policy-multi-peripheral-multi-register-back-to-back-readiness-audit
title: APB no-policy multi-peripheral multi-register timing readiness selected contract step
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.640?"
  - "what APB no-policy multi-peripheral multi-register timing audit found?"
  - "why does APB no-policy multi-peripheral multi-register timing need contract selection?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.641 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, multi-peripheral, multi-register, no-policy, back-to-back, readiness, contract, task-tree]
evidence: docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.640|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.641|no-policy multi-peripheral multi-register|supports only one-register peripheral completer storage|sideband data16 protection status/control storage shape' docs/IAL2_APB_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.640` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.641`, public contract selection for the
bounded 32-bit sideband-aware no-policy multi-peripheral multi-register
back-to-back timing family.

The audit found that fixed no-policy multi-register timing is already shipped
for selected 32-bit sideband and sideband data16 fixed compositions, and
multi-peripheral no-policy timing is already shipped for one-register
peripheral shapes. The missing supported shape is the 32-bit sideband-aware
multi-peripheral composition with two no-policy registers per peripheral.

In-memory 32-bit and data16 two-register no-policy multi-peripheral timing
candidates fail closed at the current multi-peripheral timing guard. `.641`
must settle public source names, 32-bit register/window shape,
requester/completer/interconnect timing requirements, report/residue
movement, support-accounting identities, diagnostics, validation, rollback,
and docs before implementation.
