---
id: ial2-apb-status-control-protected-storage-generalization-readiness-audit
title: APB status/control protected-storage generalization readiness audited
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.651?"
  - "what APB status/control protected-storage generalization audit found?"
  - "why does APB status/control protected-storage generalization need contract selection?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.652 select?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, status-control, multi-peripheral, back-to-back, readiness, task-tree]
evidence: docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT.md; docs/IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1472-ial2-apb-composition.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.651|IAL2-FEATURE-COMPLETENESS-FRONTIER\.652|status/control protected-storage generalization|status/control protected storage generalization|apb_composition_multi_peripheral_sideband_protection_status_back_to_back|apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back' docs/IAL2_APB_STATUS_CONTROL_PROTECTED_STORAGE_GENERALIZATION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.651` audits APB status/control
protected-storage generalization readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.652`, public contract selection for a
bounded status/control protected-storage generalization.

The audit found that `.638` and `.634` already ship selected 32-bit and data16
two-peripheral status/control protected storage with peripheral-owned
privileged `PPROT[0]` enforcement, requester `accepted/busy/status`,
queue-depth `1`, overflow `reject`, adjacent setup, and propagation-only
interconnect timing. `.649` separately ships the selected data16 protected
`reg0`/`reg1` multi-register family.

Contract selection is needed before behavior because the live residue still
names status/control protected storage generalization, but the exact public
shape is unsettled: new source pairs, report/static cleanup, alias/support
accounting expansion, or explicit deferral. `.652` must settle scope, width
families, source/report movement, diagnostics, validation, rollback, docs, and
Knowledge Map before any parser, generator, sample, support-accounting, JSON,
HDL/runtime, APB, AXI, AHB, or VHDL behavior change.
