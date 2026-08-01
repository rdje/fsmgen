---
id: normalized-semantic-symbol-package-import-name-list
title: Normalized semantic symbol contracts expose package imports as name lists
answers:
  - "what shape does semantic.symbol_contract.package_imports use?"
  - "what does semantic.forward_ir.intent_hir.symbol_contract.package_imports contain?"
  - "are symbol-contract package imports public package internals?"
  - "where is normalized semantic package-import name-list metadata tracked?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, symbol-contract, intent-hir, package-imports, public-api]
evidence: >-
  perl/FSM/IR/IntentHIRBuilder.pm; perl/FSM/Support/NormalizedSemanticSymbolContract.pm; perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/277-direct-symbol-contract-forward-ir.t; t/278-composition-symbol-contract-forward-ir.t; t/335-normalized-semantic-symbol-contract.t; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/383-contract-family-map-integrity-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t;
  t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/277-direct-symbol-contract-forward-ir.t t/278-composition-symbol-contract-forward-ir.t t/335-normalized-semantic-symbol-contract.t t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/383-contract-family-map-integrity-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`semantic.symbol_contract.package_imports` is a list of authored package names,
not a public package-spec object graph. The matching
`semantic.forward_ir.intent_hir.symbol_contract.package_imports` branch carries
the same package-name list through the IntentHIR alias.

`FSM::Support::NormalizedSemanticSymbolContract` advertises the bounded
top-level package-import key family through `package_import_count` and
`package_imports`. It also advertises
`package_import_entry_value_kinds` as `[scalar_package_name]` and
`package_import_entry_value_meaning` as `authored package-import package-name
string` on the top-level contract surfaces. In grouped
`presence_key_family_map` discovery maps, the corresponding
`*_package_import_entry_value_meaning` entries are single-element arrays
containing the same meaning string so all grouped family-map values remain
array-valued. The same metadata is delegated through the IntentHIR,
forward-IR, payload, report, and capability-manifest contract surfaces.

This boundary does not expose raw `FSM::Package::Spec` internals, package source
AST, package symbols, VHDL package emission, unrelated symbol-contract internals,
or full normalized semantic export stabilization.
