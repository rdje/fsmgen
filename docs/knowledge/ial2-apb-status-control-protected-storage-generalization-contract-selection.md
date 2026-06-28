---
id: ial2-apb-status-control-protected-storage-generalization-contract-selection
title: APB status/control protected-storage generalization contract selected
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.652?"
  - "which APB status/control protected-storage generalization contract was selected?"
  - "why is APB status/control protected-storage generalization a residue cleanup?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.653 implement?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, status-control, residue, contract, task-tree]
evidence: docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION.md; docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.652|IAL2-FEATURE-COMPLETENESS-FRONTIER\.653|status/control protected-storage generalization|status/control protected storage generalization|apb_additional_back_to_back_policies_deferred|apb_composition_multi_peripheral_sideband_protection_status_back_to_back|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back' docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.652` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.653`, a report/static residue cleanup for
the already-shipped bounded APB status/control protected-storage
generalization.

The selected public contract is the existing `.638` 32-bit status/control
protected source pair plus the existing `.634` data16 status/control protected
source pair. No new `.ppif`, `.apb`, support-accounting identity, capability
bucket, parser branch, timing branch, generated artifact, HDL behavior, APB
transaction behavior, AXI, AHB, or VHDL behavior is selected.

`.653` must refine `apb_additional_back_to_back_policies_deferred` and related
static prose so selected status/control protected storage is no longer named
as live residue. Generalized multi-peripheral multi-register timing, broader
protection-policy families, alternate widths, deeper queues, alternate
overflow, accepted-less requesters, multiple active transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
