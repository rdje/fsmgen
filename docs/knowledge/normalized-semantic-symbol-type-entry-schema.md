---
id: normalized-semantic-symbol-type-entry-schema
title: Normalized semantic symbol contracts advertise recursive type-entry schemas
answers:
  - "where are semantic.symbol_contract.types entry keys advertised?"
  - "what keys are in semantic.symbol_contract.types entries?"
  - "what kind values do symbol-contract type entries use?"
  - "where are semantic.forward_ir.intent_hir.symbol_contract.types entry keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, symbol-contract, intent-hir, types, public-api]
evidence: >-
  perl/FSM/Support/NormalizedSemanticSymbolContract.pm; perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/335-normalized-semantic-symbol-contract.t; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md;
  docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/335-normalized-semantic-symbol-contract.t t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticSymbolContract` owns the bounded recursive
type-entry schema for entries under `semantic.symbol_contract.types`.

Every advertised type entry carries the core keys `kind`, `signed`, and
`width`. Scalar type entries use the `bit` or `bits` kind, and explicit
two-state/four-state scalar intent adds the `state_model` extension key.
Aggregate type entries use the `list` or `record` kind. List entries add
recursive `items`; record entries add deterministic `member_order` plus
recursive `members`.

`FSM::Support::NormalizedSemanticIntentHIRContract` delegates the matching
`semantic.forward_ir.intent_hir.symbol_contract.types` key families through the
symbol-contract owner. The forward-IR, payload, report, and capability-manifest
surfaces republish those delegated families. Package-import internals,
already bounded constant/enum internals, unrelated forward-IR payloads, and
full normalized semantic export stabilization remain out of this fact-card
boundary.
