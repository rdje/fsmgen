---
id: normalized-semantic-optional-children
title: Normalized semantic JSON advertises optional semantic children explicitly
answers:
  - "how do embedders discover optional semantic children?"
  - "are semantic.composition and semantic.symbol_contract mandatory?"
  - "where are normalized semantic optional children advertised?"
  - "what are success_semantic_optional_child_presence_keys?"
  - "does normalized semantic JSON always include semantic.composition?"
  - "can semantic.explicit_system_contract be null?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, capability-manifest, embedding, public-api]
evidence: perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticReport.pm; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md; docs/tasks/PERL-POD-API-REFERENCE.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/330-normalized-semantic-payload-contract.t t/2105-normalized-semantic-json-booleans.t
---

`semantic.composition` and `semantic.symbol_contract` are optional success
children. Direct roots can omit the former; symbol-poor roots can omit the latter.
`protocol_intent_bundle` is optional too; `semantic.explicit_system_contract` is
a required key and can be null when no authored contract is preserved.

Discover optional children through payload `optional_child_presence_keys` /
`presence_key_family_map`, or `success_semantic_optional_child_presence_keys` /
`presence_key_family_map` at `semantic_exports.normalized_semantic_json`.
