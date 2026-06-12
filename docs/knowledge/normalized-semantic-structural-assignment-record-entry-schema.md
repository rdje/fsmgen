---
id: normalized-semantic-structural-assignment-record-entry-schema
title: Normalized semantic structural RTL advertises assignment record entry schemas
answers:
  - "where are structural_rtl_ir assignment record entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.assignment_records entries?"
  - "what is the normalized semantic structural assignment record schema?"
  - "where is the direct generated-enable assignment AST exposed?"
date: 2026-06-12
status: current
tags: [normalized-semantic-json, structural-rtl-ir, assignment-records, public-api]
evidence: perl/FSM/IR/StructuralRTLIR.pm; perl/FSM/IR/StructuralRTLIRBuilder.pm; perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/1333-direct-structural-rtl-ir-projection.t; t/163-forward-structural-rtl-ir-surface.t; t/498-structural-rtl-ir-accessor-defensive-copy-boundary-audit.t; t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.md
reverify: prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/498-structural-rtl-ir-accessor-defensive-copy-boundary-audit.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises the
bounded direct assignment-record schemas under
`semantic.forward_ir.structural_rtl_ir.assignment_records[]`.

Direct generated-enable roots populate these records for top-level
state/standalone-DT enable assignments, DT-specific WEN/EN assignments, and
LHS-level WEN/EN assignments. Each record carries `kind`, structured `lhs`,
structured `rhs`, rendered SystemVerilog assignment text, and provenance. The
`rhs` payload includes rendered expression text plus a JSON-safe AST when the
direct backend already has one.

The companion `auxiliary_assignments[]` collection remains a scalar-string
compatibility mirror for rendered assignment lines. It is not the preferred
machine-readable surface for direct generated-enable assignments.
