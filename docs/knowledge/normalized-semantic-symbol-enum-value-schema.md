---
id: normalized-semantic-symbol-enum-value-schema
title: Normalized semantic symbol contracts advertise enum map value kinds
answers:
  - "where are semantic.symbol_contract.enums value kinds advertised?"
  - "what shape does semantic.symbol_contract.enums use?"
  - "where are semantic.forward_ir.intent_hir.symbol_contract.enums value kinds advertised?"
  - "what kind of values do symbol-contract enum members carry?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, symbol-contract, intent-hir, enums, public-api]
evidence: perl/FSM/Support/NormalizedSemanticSymbolContract.pm; perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/335-normalized-semantic-symbol-contract.t; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/335-normalized-semantic-symbol-contract.t t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticSymbolContract` owns the bounded value-kind
metadata for entries under `semantic.symbol_contract.enums`.

The emitted `enums` branch is an enum-name map. Each enum entry value is a
`member_payload_map`, whose dynamic member names carry `scalar_payload` values.
The contract deliberately advertises value kinds rather than fixed member keys,
because enum member names come from the source design.

`FSM::Support::NormalizedSemanticIntentHIRContract` delegates the matching
`semantic.forward_ir.intent_hir.symbol_contract.enums` value-kind families
through the symbol-contract owner. The forward-IR, payload, report, and
capability-manifest surfaces republish those delegated families; type internals,
package-import internals, already bounded constant internals, and full
normalized semantic export stabilization remain out of this fact-card boundary.
