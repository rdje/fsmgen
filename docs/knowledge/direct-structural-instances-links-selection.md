---
id: direct-structural-instances-links-selection
title: Direct StructuralRTLIR roots intentionally keep instance/link arrays empty
answers:
  - "do direct roots populate structural_rtl_ir instances?"
  - "do direct roots populate structural_rtl_ir declared_links or resolved_links?"
  - "what is the direct StructuralRTLIR instances links selector outcome?"
  - "where are direct StructuralRTLIR instance and link facts represented?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, instances, links, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.md; docs/TASK_TREE.md; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/IR/StructuralRTLIR.pm; t/1333-direct-structural-rtl-ir-projection.t; t/162-composition-top-structural-rtl-ir-surface.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/162-composition-top-structural-rtl-ir-surface.t t/163-forward-structural-rtl-ir-surface.t
---

Selector `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms that direct-root
`StructuralRTLIR` summaries intentionally keep `instances[]`,
`declared_links[]`, and `resolved_links[]` empty.

The populated instance/link structural contract belongs to composition-top and
generated wrapper/top paths built through
`StructuralRTLIRBuilder->build_from_composition_plan`. Direct roots are leaf
generated modules; no direct implementation leaf is warranted until a future
source model introduces real direct-root child instances or direct-root links.
