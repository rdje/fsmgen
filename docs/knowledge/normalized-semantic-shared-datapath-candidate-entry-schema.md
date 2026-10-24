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
  - "are shared-datapath declared_type_name and declared_type_spec always present together?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_shared_candidate.py docs/audits/mcp-api-reference-20261023/shared-candidate-qualified.json.gz --current-contracts
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises bounded schemas
under `semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]`:
candidate/optional declared-type, contributor/`bound_connection_expr`, contributor
`drive_intent`/nested `rhs_enable_families[]`, aggregate-enable/family-contributor
and multi/same-value assertion metadata. Payload/report contracts and the manifest
inherit these lists through the normalized helper chain. The recorded runtime
audit checks strict composition semantic JSON against exact entry schemas.
Contributor `intent_hir`, `lowered_rtl_ir` and `structural_rtl_ir` remain bounded
child delegates rather than duplicated candidate schemas.

Candidate and contributor `declared_type_name`/`declared_type_spec` are independently
optional: the builder emits each only when its value is defined. Check keys
separately; their family list does not promise both on every entry.
Replay checks current contract/builder code and dated candidate/type guides;
nested families remain delegated. No source epoch reruns.

`perl/FSM/Composition/SharedDatapathCandidateBuilder.pm`
