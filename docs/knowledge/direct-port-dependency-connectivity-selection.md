---
id: direct-port-dependency-connectivity-selection
title: Direct input-port generated-enable RHS targets are the selected port connectivity slice
answers:
  - "what is the selected direct port dependency connectivity slice?"
  - "are direct input port generated-enable RHS dependencies selected?"
  - "why is direct port dependency connectivity not covered by net connectivity?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, ports, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t
reverify: rg -n 'R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2|input-port generated-enable RHS target' docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md docs/TASK_TREE.md
---

`R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2` is the selected next
direct port dependency implementation slice.

The current direct structural net connectivity pass maps generated-enable
assignment-record RHS dependencies only when the dependency name is also a
direct `nets[]` entry. Direct input ports such as guard/data ports can appear
in those assignment-record RHS ASTs but are not direct nets, so their
assignment-record consumers are not structurally visible today.

The selected `.2` slice is to expose those generated-enable RHS consumers as
structured targets on the matching direct input port entries. Output-port
source/driver connectivity, output-drive/always-block consumers, direct
instances/links, and HDL emission remain outside that slice.
