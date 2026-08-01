---
id: ial2-feature-completeness-priority
title: IAL2 remains the feature-completeness priority on the SystemVerilog-backed path
answers:
  - "what is the current feature completeness priority?"
  - "should IAL2 be prioritized before VHDL?"
  - "what task owns IAL2 feature completeness?"
  - "what is the next IAL2 PNT frontier?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.812 select?"
  - "what follows the two-subordinate exact-two paired AHB alias?"
  - "can IAL2 feature completion require new IAL1 features?"
date: 2026-08-01
status: current
tags: [ial2, systemverilog, roadmap, task-tree, feature-completeness]
evidence: >-
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ROADMAP_V2.md;
  docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: >-
  rg -n 'Status: `active`|Current frontier|Next action|IAL2-FEATURE-COMPLETENESS-FRONTIER\.813'
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md
---

IAL2 remains the active feature-completeness priority on the shipped
SystemVerilog-backed path. The exact frontier is intentionally not duplicated
here: read `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`, then use its
frontier row as the current authority.

IAL2 work may select and ship owned IAL1 or IAL0 prerequisites when a higher-
layer feature cannot be expressed correctly without them. VHDL remains a
separate backend lane rather than a reason to stop feature-completeness work.

Historical priority-card prose is exactly recoverable with:
`git show aadbd14a5:docs/knowledge/ial2-feature-completeness-priority.md`.
