---
id: ial2-post-apb-sideband-multi-register-back-to-back-next-slice-selection
title: APB data16 back-to-back contract selection follows sideband multi-register timing
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.623?"
  - "what comes after APB sideband multi-register back-to-back behavior?"
  - "which task owns APB data16 back-to-back contract selection?"
  - "why choose APB data16 back-to-back before protection timing?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.624?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, sideband, multi-register, back-to-back, selector, task-tree]
evidence: docs/IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.623|IAL2-FEATURE-COMPLETENESS-FRONTIER\.624|data16-only contract selection|apb_requester_transfer_sideband_data16|apb_back_to_back_policy_deferred|protection-only timing' docs/IAL2_POST_APB_SIDEBAND_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.623` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.624`, public contract selection for the
bounded APB sideband-aware data16 back-to-back timing-policy family, after
`.622` shipped selected 32-bit sideband-aware multi-register timing.

The selector changes no behavior.

Live report probes showed representative data16, protection, and
data16-protection APB sources still report no `back_to_back_policy` and keep
`apb_back_to_back_policy_deferred`.

Data16 is selected before protection because it widens the shipped sideband
queue and adjacent-completer paths to 16-bit data and `PSTRB width 2` without
adding register-local denied-access side effects. Protection-only timing and
combined data16-protection timing remain future exact owners.

`.624` must settle exact `.ppif`/`.apb` sample names, endpoint/fixed
composition scope, `accepted/busy/status` requester requirements, data16
register/address/strobe compatibility, report/residue movement, support
accounting, diagnostics, validation, rollback, and deferrals before behavior
changes.
