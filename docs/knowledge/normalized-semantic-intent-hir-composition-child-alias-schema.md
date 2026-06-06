---
id: normalized-semantic-intent-hir-composition-child-alias-schema
title: Normalized semantic IntentHIR advertises composition child alias schemas
answers:
  - "where are semantic.forward_ir.intent_hir composition_children entry keys advertised?"
  - "what keys are in semantic.forward_ir.intent_hir composition_children entries?"
  - "does intent_hir composition_children reuse composition child schemas?"
  - "where are intent-HIR composition child alias keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, intent-hir, composition, public-api]
evidence: perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/339-normalized-semantic-intent-hir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/339-normalized-semantic-intent-hir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticIntentHIRContract` advertises bounded alias
entry schemas under `semantic.forward_ir.intent_hir.composition_children[]`,
`semantic.forward_ir.intent_hir.composition_generated_children[]`, and
`semantic.forward_ir.intent_hir.composition_standalone_dt_children[]`.

Those aliases delegate to the already bounded `semantic.composition` child and
standalone-DT child schema helpers. The forward-IR, semantic payload, normalized
semantic report, and capability manifest layers inherit the same key families
through their helper chains.

IntentHIR also advertises parameter-override alias key families for
`semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]`
and
`semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]`
by delegating to the composition child and generated-child alias owners.

Nested child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries
remain delegated to their existing bounded child contracts instead of being
duplicated inside the IntentHIR alias schemas.
