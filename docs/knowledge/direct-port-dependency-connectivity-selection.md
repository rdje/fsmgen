---
id: direct-port-dependency-connectivity-selection
title: Direct input-port generated-enable RHS targets are structural port connectivity
answers:
  - "what is the selected direct port dependency connectivity slice?"
  - "are direct input port generated-enable RHS dependencies selected?"
  - "are direct input port generated-enable RHS dependencies structural targets?"
  - "why is direct port dependency connectivity not covered by net connectivity?"
date: 2026-06-12
status: current
tags: [direct-hdl, structural-rtl-ir, ports, task-tree]
evidence: docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2` is the shipped first
direct port dependency implementation slice.

The direct structural net connectivity pass maps generated-enable
assignment-record RHS dependencies only when the dependency name is also a
direct `nets[]` entry. Direct input ports such as guard/data ports can appear
in those assignment-record RHS ASTs but are not direct nets, so the port slice
records their assignment-record consumers on the matching port entries.

Direct input ports consumed by generated-enable assignment-record RHS ASTs now
expose structured `targets[]` entries on `structural_rtl_ir.ports[]`. Each
target reuses the generated-enable assignment-record endpoint shape used by
direct net `targets[]`: `kind`, `assignment_lhs`, `assignment_kind`, `family`,
and `role`.

Output-port source/driver connectivity, output-drive/always-block consumers,
direct instances/links, and HDL emission remain outside that slice.
