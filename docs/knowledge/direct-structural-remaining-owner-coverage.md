---
id: direct-structural-remaining-owner-coverage
title: Remaining direct StructuralRTLIR gaps have proposed task-tree owners
answers:
  - "who owns the remaining direct StructuralRTLIR gaps?"
  - "is direct port dependency connectivity task-tree tracked?"
  - "is direct output-drive consumer connectivity task-tree tracked?"
  - "is direct instances and links tracking owned?"
  - "are full direct HDL rerouting and VHDL rerouting task-tree tracked?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, task-tree, roadmap]
evidence: docs/TASK_TREE.md; docs/tasks/R11-DIRECT-STRUCTURAL-REMAINING-OWNER-COVERAGE.md; docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md; docs/tasks/R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.md; docs/tasks/R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.md; docs/tasks/R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.md; docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'R11-DIRECT-STRUCTURAL-(PORT-DEPENDENCY-CONNECTIVITY|OUTPUT-CONSUMERS|INSTANCES-LINKS|FULL-HDL-REROUTING|VHDL-REROUTING)' docs/TASK_TREE.md docs/tasks ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

The remaining direct `StructuralRTLIR` roadmap gaps are task-tree owned by
proposed owner trees before implementation:

- `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY` owns direct port
  dependency connectivity.
- `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS` owns direct output-drive and
  always-block consumer connectivity.
- `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS` owns the direct instances/links
  structural contract question.
- `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING` owns broader direct SystemVerilog
  rerouting through `StructuralRTLIR`.
- `R11-DIRECT-STRUCTURAL-VHDL-REROUTING` owns direct VHDL rerouting through
  `StructuralRTLIR`.

They are proposed, not implementation-active. A future PNT slice must activate
the relevant selector leaf before code, test, source, generated-artifact, or
config changes.
