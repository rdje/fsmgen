---
id: ial2-axi-manager-post-concrete-id-static-validation-next-slice-selection
title: Post concrete-ID static validation selector chooses per-ID queue readiness
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.89 select?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.89?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.88?"
  - "what comes after concrete-ID same-ID static validation?"
  - "why not implement AXI per-ID issue-order queues directly?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.90?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, same-id, concrete-id, per-id-queues, task-tree]
evidence: docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md; docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md; docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.89|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.90|POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION|per-ID issue-order queue readiness|public same-ID reuse policy' docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.89` is a selector after `.88` made
unsupported same-family concrete-ID reuse fail closed.

It selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.90`: audit AXI per-ID
issue-order queue readiness after concrete-ID static validation.

The selector does not change parser, generator, `.isf`, `.fsm`, SystemVerilog,
sample, support-accounting, check JSON, semantic JSON, or validation behavior.
It records that post-`.88` residue is still honest: accepted concrete-ID
same-ID reuse behavior and per-ID issue-order queues are not implemented.

Direct per-ID queue behavior is deferred until `.90` audits whether the next
owner should be public same-ID reuse policy selection, generated queue or
scoreboard substrate, concrete-ID response-demux prerequisites, report/static
residue refinement, a smaller IAL1/IAL0/SystemVerilog prerequisite, or a
deliberate deferral.
