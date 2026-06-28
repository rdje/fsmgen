---
id: ial2-apb-data16-protection-multi-peripheral-multi-register-back-to-back-readiness-audit
title: APB data16-protection multi-peripheral multi-register contract selection is next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.647?"
  - "is APB data16-protection multi-peripheral multi-register timing ready?"
  - "why select APB data16-protection multi-peripheral multi-register contract next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.648 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, multi-peripheral, multi-register, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_POST_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_NO_POLICY_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif; ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.647|IAL2-FEATURE-COMPLETENESS-FRONTIER\.648|data16-protection multi-peripheral multi-register|apb_composition_multi_register_sideband_data16_protection_status_back_to_back|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back|_multi_peripheral_completers_are_selected_sideband_data16_protection_timing_shape' docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.647` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.648`, public contract selection for a
bounded APB sideband-aware data16-protection multi-peripheral multi-register
back-to-back timing family.

The audit found that fixed data16-protection multi-register timing and
selected multi-peripheral data16-protection status/control timing are shipped,
but no explicit public
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection`
back-to-back source exists yet. The current implementation accepts the fixed
`reg0`/`reg1` protected shape for fixed composition and the status/control
protected shape for multi-peripheral composition.

`.648` must settle exact source names, storage/policy shape, report/residue
movement, support accounting, diagnostics, validation, rollback, docs, and
Knowledge Map before any behavior change. Generalized register shapes, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
