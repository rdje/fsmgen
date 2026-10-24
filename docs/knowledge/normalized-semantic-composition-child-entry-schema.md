---
id: normalized-semantic-composition-child-entry-schema
title: Normalized semantic composition advertises child entry schemas
answers:
  - "where are semantic.composition children entry keys advertised?"
  - "what keys are in semantic.composition.children entries?"
  - "what keys are in semantic.composition.generated_children entries?"
  - "where are composition generated_children entry keys advertised?"
  - "where are grouped composition child key families advertised?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, composition, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_composition_closure.py docs/audits/mcp-api-reference-20261023/composition-final-qualified.json.gz --current-contracts
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded shallow
schemas for `semantic.composition.children[]` and
`semantic.composition.generated_children[]`, inherited by payload/report contracts
and the capability manifest through the normalized helper chain. The recorded
runtime audit checks strict composition semantic JSON over `fsm/apb_tb.fsm`
against exact child/generated keys. Generated entries include
`parameter_override_count` and `parameter_overrides`; their nested alias belongs
to `normalized-semantic-generated-child-parameter-override-alias-schema`.
Child `intent_hir`, `lowered_rtl_ir` and `structural_rtl_ir` summaries remain
bounded delegates, not duplicated schemas.

Child families use full report names in `presence_key_family_map`;
`semantic_presence_key_family_map` drops leading `success_` for flattened HIR.
Only the report map includes envelope `composition_presence_keys`. Replay checks
current code with dated guides; it does not rerun or extend the source epoch.
