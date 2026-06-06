---
id: normalized-semantic-composition-child-entry-schema
title: Normalized semantic composition advertises child entry schemas
answers:
  - "where are semantic.composition children entry keys advertised?"
  - "what keys are in semantic.composition.children entries?"
  - "what keys are in semantic.composition.generated_children entries?"
  - "where are composition generated_children entry keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, composition, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/333-normalized-semantic-composition-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded shallow
entry schemas under `semantic.composition.children[]` and
`semantic.composition.generated_children[]`.

The payload/report contracts and capability manifest inherit those key families
through the normalized semantic contract helper chain. The runtime contract audit
checks a strict composition semantic JSON export over `fsm/apb_tb.fsm` against
the exact child and generated-child entry key sets. Generated-child entries now
include `parameter_override_count` and `parameter_overrides`; the nested
generated-child parameter-override alias schema is owned by
`normalized-semantic-generated-child-parameter-override-alias-schema`.

Child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries remain
delegated to their existing bounded child contracts instead of being duplicated
inside the composition entry schema.
