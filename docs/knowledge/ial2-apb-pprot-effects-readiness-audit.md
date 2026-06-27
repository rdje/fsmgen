---
id: ial2-apb-pprot-effects-readiness-audit
title: APB PPROT effects readiness selects public policy contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.595?"
  - "what comes after APB data16 widths?"
  - "is APB PPROT access-control ready to implement?"
  - "does APB PPROT have access-control effects now?"
  - "what must APB PPROT policy contract selection decide?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, readiness, contract, task-tree]
evidence: docs/IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT.md; docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.595|IAL2-FEATURE-COMPLETENESS-FRONTIER\.596|apb_protection_policy_effects_deferred|PPROT|protection access-control|public APB `PPROT` access-control effects contract' docs/IAL2_APB_PPROT_EFFECTS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.595` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.596`, public APB `PPROT`
access-control effects contract selection, without behavior changes.

The current sideband-aware APB surface already propagates requester `PPROT`
through bus, fixed-composition, and multi-peripheral interconnect paths, and
completers already sample `PPROT` during setup. Reports still carry
`apb_protection_policy_effects_deferred`, because no access-control policy is
implemented yet.

Existing generated IAL1/IAL0 expression and conditional-action support is
sufficient for bounded static policy checks. `.596` must settle public policy
vocabulary, policy scope, denied read/write behavior, `PSTRB` interaction,
composition/interconnect effects, reports, support identities, diagnostics,
validation, rollback, and the next implementation owner before behavior work.
