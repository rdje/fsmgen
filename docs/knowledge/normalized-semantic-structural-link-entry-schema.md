---
id: normalized-semantic-structural-link-entry-schema
title: Normalized semantic structural RTL advertises link entry schemas
answers:
  - "where are structural_rtl_ir declared_links entry keys advertised?"
  - "where are structural_rtl_ir resolved_links entry keys advertised?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.declared_links entries?"
  - "what keys are in semantic.forward_ir.structural_rtl_ir.resolved_links entries?"
  - "what is the normalized semantic structural link entry schema?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, structural-rtl-ir, links, public-api]
evidence: perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/341-normalized-semantic-structural-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticStructuralRTLIRContract` advertises bounded
entry schemas under `semantic.forward_ir.structural_rtl_ir.declared_links[]`
and `semantic.forward_ir.structural_rtl_ir.resolved_links[]`.

Both public key families use the same ordered link entry shape:
`origin_kind`, `raw_token`, `source`, and `target`. Payload/report contracts
and the capability manifest inherit those lists through the normalized
semantic contract helper chain.
