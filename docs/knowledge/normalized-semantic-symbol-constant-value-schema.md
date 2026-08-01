---
id: normalized-semantic-symbol-constant-value-schema
title: Normalized semantic symbol contracts advertise scalar and list constant value schemas
answers:
  - "where are semantic.symbol_contract.constants value keys advertised?"
  - "what keys are in semantic.symbol_contract.constants scalar entries?"
  - "what keys are in semantic.symbol_contract.constants list entries?"
  - "where are semantic.forward_ir.intent_hir.symbol_contract.constants value keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, symbol-contract, intent-hir, constants, public-api]
evidence: >-
  perl/FSM/Support/NormalizedSemanticSymbolContract.pm; perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/335-normalized-semantic-symbol-contract.t; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md;
  docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/335-normalized-semantic-symbol-contract.t t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticSymbolContract` owns the bounded value schema
for entries under `semantic.symbol_contract.constants`.

Every advertised constant value entry carries the core `kind` key. Scalar
constant values add `payload`; list constant values add `items`. Runtime list
items reuse the same value-entry schema, so scalar list leaves carry `kind` and
`payload`.

`FSM::Support::NormalizedSemanticIntentHIRContract` delegates the matching
`semantic.forward_ir.intent_hir.symbol_contract.constants` key families through
the symbol-contract owner. The forward-IR, payload, report, and capability
manifest surfaces republish those delegated families; enum/type internals,
package-import internals, and full normalized semantic export stabilization
remain out of this fact-card boundary.
