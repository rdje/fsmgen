---
id: normalized-semantic-output-drive-entry-schema
title: Normalized semantic lowered RTL advertises output-drive entry schemas
answers:
  - "where are output_drive_families entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.output_drive_families entries?"
  - "what keys are in output_drive_families rhs_enable_families entries?"
  - "where are output-drive rhs-enable-family keys advertised?"
date: 2026-06-05
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, output-drive, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises the bounded
entry schemas under
`semantic.forward_ir.lowered_rtl_ir.output_drive_families[]`.

The public key families cover output-drive family entries and nested
`rhs_enable_families[]` entries. Payload/report contracts and the capability
manifest inherit those lists through the normalized semantic contract helper
chain.
