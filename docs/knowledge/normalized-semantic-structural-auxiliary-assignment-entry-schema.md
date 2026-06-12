---
id: normalized-semantic-structural-auxiliary-assignment-entry-schema
title: Normalized semantic structural RTL advertises auxiliary assignment scalar-string entries
answers:
  - "where are structural_rtl_ir auxiliary assignment entries advertised?"
  - "what is the normalized semantic structural auxiliary assignment entry schema?"
  - "what are semantic.forward_ir.structural_rtl_ir auxiliary_assignments entries?"
  - "are structural_rtl_ir auxiliary assignments shell-only?"
date: 2026-06-12
status: current
tags: [normalized-semantic-json, structural-rtl-ir, auxiliary-assignments, public-api]
evidence: perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t; t/196-generated-module-info-builder.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/06-composition-advanced.md; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/196-generated-module-info-builder.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded entry value kind for
`semantic.forward_ir.structural_rtl_ir.auxiliary_assignments[]`.

Those entries are scalar strings containing generated SystemVerilog continuous
assignment line text, such as `assign tap_a = start;`. Composition tops use
them for structural helper assignments, and direct roots use them for the
already-rendered generated enable assignment lines. They are not parsed
`lhs`/`rhs` records, and the public value-kind family is `scalar_string`.

Structural ports, nets, links, instances, nested instance interface ports,
parameter overrides, and port bindings are advertised by their separate
normalized-semantic structural RTL fact cards.
