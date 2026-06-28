---
id: ial2-apb-status-control-protected-storage-residue-cleanup
title: APB status/control protected-storage residue cleanup shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.653?"
  - "what APB status/control protected-storage residue cleanup shipped?"
  - "does APB status/control protected storage remain live timing residue?"
  - "what APB owner follows status/control residue cleanup?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, status-control, residue, behavior, task-tree]
evidence: docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP.md; docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_CONTRACT_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.653|IAL2-FEATURE-COMPLETENESS-FRONTIER\.654|selected status/control protected storage is complete|status/control protected storage generalization|apb_additional_back_to_back_policies_deferred' docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_RESIDUE_CLEANUP.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm perl/FSM/Support/LanguageSurfaceSection.pm t/1472-ial2-apb-composition.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.653` ships the `.652` selected
report/static cleanup for APB status/control protected-storage residue.

`apb_additional_back_to_back_policies_deferred` now says selected
status/control protected storage is complete for the bounded 32-bit and
data16 two-peripheral families. It no longer names status/control protected
storage generalization as live residue. Generalized APB multi-peripheral
multi-register timing, deeper queues, alternate overflow, accepted-less
requesters, multiple active transfers, bus matrices, scoreboards, broader
protection policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.

No public source, support-accounting identity, parser branch, timing branch,
generated artifact, HDL/runtime behavior, APB transaction behavior, AXI, AHB,
or VHDL behavior changed. `.653` selects `.654`, readiness audit for
generalized APB multi-peripheral multi-register timing.
