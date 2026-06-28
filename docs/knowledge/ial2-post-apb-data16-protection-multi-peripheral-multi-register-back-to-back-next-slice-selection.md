---
id: ial2-post-apb-data16-protection-multi-peripheral-multi-register-back-to-back-next-slice-selection
title: APB status/control protected-storage generalization readiness selected next
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.650?"
  - "what APB owner follows data16-protection multi-peripheral multi-register timing?"
  - "why select APB status/control protected-storage generalization readiness next?"
  - "what will IAL2-FEATURE-COMPLETENESS-FRONTIER.651 audit?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, status-control, multi-peripheral, multi-register, back-to-back, selection, task-tree]
evidence: docs/IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_CONTRACT_SELECTION.md; docs/IAL2_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_READINESS_AUDIT.md; docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.650|IAL2-FEATURE-COMPLETENESS-FRONTIER\.651|status/control protected-storage generalization|status/control protected storage generalization|apb_additional_back_to_back_policies_deferred' docs/IAL2_POST_APB_DATA16_PROTECTION_MULTI_PERIPHERAL_MULTI_REGISTER_BACK_TO_BACK_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.650` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.651`, a readiness audit for APB
status/control protected-storage generalization.

The next owner is an audit because `.649` shipped the explicit selected
data16-protection `reg0`/`reg1` multi-peripheral multi-register timing family,
while `.638` and `.634` already ship selected 32-bit and data16
status/control protected timing families. The narrowed live residue now names
status/control protected storage generalization before generalized
multi-peripheral multi-register shapes.

`.651` must decide whether the next exact owner is public contract selection
for a bounded status/control protected-storage generalization, direct
implementation of one already-selected status/control protected shape, a
smaller source-shape/report-static prerequisite, or explicit deferral. It must
keep generalized register shapes, queue depths other than `1`, overflow
policies other than `reject`, accepted-less requesters, multiple active APB
transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL deferred.
