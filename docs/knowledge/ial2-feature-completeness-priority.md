---
id: ial2-feature-completeness-priority
title: IAL2 is the current feature-completeness priority on the SV-backed path
answers:
  - "what is the current feature completeness priority?"
  - "should IAL2 be prioritized before VHDL?"
  - "what task owns IAL2 feature completeness?"
  - "what is the next IAL2 PNT frontier?"
  - "can IAL2 feature completion require new IAL1 features?"
date: 2026-06-12
status: current
tags: [ial2, ial1, ial0, systemverilog, roadmap, task-tree, feature-completeness]
evidence: docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER|IAL2 feature completeness|IAL1/IAL0/SV prerequisites|VHDL backend/reroute' docs/TASK_TREE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

The current feature-completeness priority is IAL2 on the
SystemVerilog-backed path.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.1` owns the next PNT selector. It must audit
the shipped `.ppif`/Valid-Ready surfaces, identify missing IAL2
feature-completeness work, and select the next exact slice before behavior
changes. The selected IAL2 work may include required IAL1 or IAL0/SV support,
but only when those prerequisites are explicit, task-tree owned, documented,
and regression-backed. VHDL backend/reroute work remains deferred until the
SV-backed IAL0/IAL1/IAL2 path is feature complete.
