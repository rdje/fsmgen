---
id: normalized-semantic-composition-standalone-dt-child-entry-schema
title: Normalized semantic composition advertises standalone-DT child entry schemas
answers:
  - "where are semantic.composition standalone_dt_children entry keys advertised?"
  - "what keys are in semantic.composition.standalone_dt_children entries?"
  - "where are composition standalone-DT child entry keys advertised?"
  - "what nested standalone-DT child metadata is public in normalized semantic JSON?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, composition, standalone-dt, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/333-normalized-semantic-composition-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded shallow
entry schemas under `semantic.composition.standalone_dt_children[]`.

The standalone-DT child entries cover the reusable child identity fields, DT
names, enable-family metadata, module enable-family metadata, nested
standalone-DT multi-drive target metadata, and delegated child `intent_hir`,
`lowered_rtl_ir`, and `structural_rtl_ir` summaries.

The standalone-DT multi-drive target and assertion key families are delegated to
the already bounded lowered-RTL standalone-DT multi-drive target/assertion owner
instead of being duplicated as independent composition-only shapes.
