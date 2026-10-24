---
id: normalized-semantic-composition-standalone-dt-child-entry-schema
title: Normalized semantic composition advertises standalone-DT child entry schemas
answers:
  - "where are semantic.composition standalone_dt_children entry keys advertised?"
  - "what keys are in semantic.composition.standalone_dt_children entries?"
  - "where are composition standalone-DT child entry keys advertised?"
  - "what nested standalone-DT child metadata is public in normalized semantic JSON?"
  - "which standalone-DT composition child metadata fields are arrays or objects?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, composition, standalone-dt, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md; perl/FSM/Composition/ChildExportBuilder.pm
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_composition_dt.py docs/audits/mcp-api-reference-20261023/composition-dt-qualified.json.gz --current-contracts
---

`FSM::Support::NormalizedSemanticCompositionContract` owns bounded shallow
`semantic.composition.standalone_dt_children[]`: reusable child identity, DT
names, enable/module-enable metadata, multi-drive targets and delegated
`intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir` summaries.

Per-DT `standalone_dt_enable_families[]` and multi-drive targets are arrays;
`standalone_dt_module_enable_family` and each target's `multi_drive_assertion`
are objects. Target/assertion keys delegate to the existing bounded lowered-RTL
owner, without an independent composition-only schema.
