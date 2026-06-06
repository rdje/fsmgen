---
id: normalized-semantic-shared-datapath-candidate-entry-schema
title: Normalized semantic lowered RTL advertises shared-datapath candidate entry schemas
answers:
  - "where are composition_shared_datapath_candidates entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates entries?"
  - "what keys are in shared-datapath candidate contributor entries?"
  - "what keys are in shared-datapath candidate contributor drive_intent entries?"
  - "where are shared-datapath contributor drive-intent rhs_enable_families keys advertised?"
  - "where are shared-datapath aggregate enable and assertion metadata keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/340-normalized-semantic-lowered-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises the bounded
entry schemas under
`semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]`.

The public key families cover candidate entries, optional declared-type
extension keys, contributor entries, contributor `bound_connection_expr`
metadata, contributor `drive_intent` entries, nested drive-intent
`rhs_enable_families[]` entries, aggregate enable-family entries,
aggregate-family contributor entries, and multi/same-value assertion metadata.
Payload/report contracts and the capability manifest inherit those lists
through the normalized semantic contract helper chain, and the runtime contract
audit checks a strict composition semantic JSON export against those exact
entry schemas.

Contributor child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`
summaries remain delegated to their existing bounded child contracts instead of
being duplicated inside the shared-datapath candidate schema.
