---
id: normalized-semantic-standalone-dt-multi-drive-entry-schema
title: Normalized semantic lowered RTL advertises standalone-DT multi-drive entry schemas
answers:
  - "where are standalone_dt_multi_drive_targets entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.standalone_dt_multi_drive_targets entries?"
  - "what keys are in standalone_dt_multi_drive_targets multi_drive_assertion metadata?"
  - "where are standalone-DT multi-drive assertion metadata keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, standalone-dt, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises the bounded
entry schema under
`semantic.forward_ir.lowered_rtl_ir.standalone_dt_multi_drive_targets[]`.

The public key families cover standalone-DT target entries and nested
`multi_drive_assertion` metadata. Payload/report contracts and the capability
manifest inherit those lists through the normalized semantic contract helper
chain, and the runtime contract audit checks the emitted standalone `?dt`
semantic JSON entry against those exact keys.
