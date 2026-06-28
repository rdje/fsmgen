---
id: ial2-apb-data16-protection-back-to-back-readiness-audit
title: APB sideband multi-register timing prerequisite selected before data16/protection back-to-back
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.620?"
  - "what APB back-to-back owner follows data16/protection readiness?"
  - "why is APB sideband multi-register back-to-back contract selection next?"
  - "why not implement APB data16/protection back-to-back directly?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, multi-register, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; ppif/apb_completer_multi_register_sideband.ppif; ppif/apb_composition_multi_register_sideband.ppif; ppif/apb_composition_multi_peripheral_sideband.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.620|IAL2-FEATURE-COMPLETENESS-FRONTIER\.621|sideband-aware multi-register back-to-back|multi-register timing-policy prerequisite|apb_back_to_back_policy_deferred' docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.620` audits APB data16/protection
back-to-back timing-policy readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.621`, public contract selection for a
bounded APB sideband-aware multi-register back-to-back timing-policy
prerequisite.

The audit changes no behavior.

The key blocker is multi-register timing propagation. Current requester,
completer, and composition guards are bounded to selected 32-bit no-sideband
or selected 32-bit sideband-aware one-register timing-policy families, while
the shipped data16/protection completer and composition samples all use
multi-register storage.

The selected prerequisite keeps the lower-risk 32-bit sideband family first:
it can prove adjacent setup admission and fixed/multi-peripheral propagation
for multi-register completers before adding data16 strobe-width changes or
protection-policy denied-access semantics.

Data16 timing behavior, protection timing behavior, combined data16-protection
timing behavior, deeper queues, alternate overflow, accepted-less requesters,
multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
