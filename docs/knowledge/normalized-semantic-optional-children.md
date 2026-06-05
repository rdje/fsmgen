---
id: normalized-semantic-optional-children
title: Normalized semantic JSON advertises optional semantic children explicitly
answers:
  - "how do embedders discover optional semantic children?"
  - "are semantic.composition and semantic.symbol_contract mandatory?"
  - "where are normalized semantic optional children advertised?"
  - "what are success_semantic_optional_child_presence_keys?"
  - "does normalized semantic JSON always include semantic.composition?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, capability-manifest, embedding, public-api]
evidence: perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticReport.pm; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t t/297-capability-manifest.t
---

`semantic.composition` and `semantic.symbol_contract` are optional success
payload children in public normalized semantic JSON. They are not mandatory on
every successful report: direct roots can omit `semantic.composition`, and
symbol-poor roots can omit `semantic.symbol_contract`.

Embedders should discover the optional family from the payload contract's
`optional_child_presence_keys` / `presence_key_family_map` fields and from
`success_semantic_optional_child_presence_keys` / `presence_key_family_map`
inside `semantic_exports.normalized_semantic_json`.
