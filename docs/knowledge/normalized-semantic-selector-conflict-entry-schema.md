---
id: normalized-semantic-selector-conflict-entry-schema
title: Normalized semantic lowered RTL advertises selector-conflict entry schemas
answers:
  - "where are selector_conflict_targets entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets entries?"
  - "what keys are in selector_conflict_targets rhs_enable_families entries?"
  - "where are selector conflict assertion metadata keys advertised?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, selector-conflicts, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises the bounded
entry schemas under
`semantic.forward_ir.lowered_rtl_ir.selector_conflict_targets[]`.

The public key families cover selector target entries, nested
`rhs_enable_families[]` entries, multi-value assertion metadata, and same-value
assertion metadata. Payload/report contracts and the capability manifest
inherit those lists through the normalized semantic contract helper chain.
