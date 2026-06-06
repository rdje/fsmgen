---
id: normalized-semantic-composition-child-parameter-override-alias-schema
title: Normalized semantic composition advertises child parameter-override alias schemas
answers:
  - "where are semantic.composition.children parameter_overrides entry keys advertised?"
  - "what keys are in semantic.composition.children parameter_overrides entries?"
  - "does composition child parameter_overrides reuse structural instance parameter override schemas?"
  - "where are semantic.forward_ir.intent_hir composition_children parameter_overrides entry keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, composition, intent-hir, parameter-overrides, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/333-normalized-semantic-composition-contract.t; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/333-normalized-semantic-composition-contract.t t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded alias
entry schemas under `semantic.composition.children[].parameter_overrides[]`.

Those composition child parameter-override aliases delegate to the already
bounded structural instance parameter-override helpers. The public core key
family covers `name`, `origin_kind`, `raw_value_ast`, `value_kind`,
`value_payload`, and `value_text`; the raw-value and value-metadata extension
families reuse the same optional key families as
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`.

`FSM::Support::NormalizedSemanticIntentHIRContract` advertises the matching
`semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]`
alias key families by delegating through the composition child schema owner.
Generated-child parameter-override aliases are owned separately by
`normalized-semantic-generated-child-parameter-override-alias-schema`; standalone-DT
child parameter-override schemas remain out of this specific alias boundary.
