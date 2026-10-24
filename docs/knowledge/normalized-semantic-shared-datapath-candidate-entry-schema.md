---
id: normalized-semantic-shared-datapath-candidate-entry-schema
title: Shared-datapath entry and assertion schemas
answers:
  - "where are composition_shared_datapath_candidates entry keys advertised?"
  - "what keys are in semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates entries?"
  - "what keys are in shared-datapath candidate contributor entries?"
  - "what keys are in shared-datapath candidate contributor drive_intent entries?"
  - "where are shared-datapath contributor drive-intent rhs_enable_families keys advertised?"
  - "where are shared-datapath aggregate enable and assertion metadata keys advertised?"
  - "are shared-datapath declared_type_name and declared_type_spec always present together?"
  - "how do shared-datapath multi-value and same-value assertions choose inputs?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, lowered-rtl-ir, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; perl/FSM/Support/NormalizedSemanticForwardIRContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; t/340-normalized-semantic-lowered-rtl-ir-contract.t; t/334-normalized-semantic-forward-ir-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_shared_aggregate.py docs/audits/mcp-api-reference-20261023/shared-aggregate-qualified.json.gz --current-contracts
---

`FSM::Support::NormalizedSemanticLoweredRTLIRContract` advertises bounded schemas at
`semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]`:
candidate/optional type, contributor/`bound_connection_expr`, `drive_intent`/
`rhs_enable_families[]`, aggregate-enable/contributor and multi/same-value assertions.
Payload/report/manifest inherit via normalized helpers. Strict composition JSON
runtime audit checks exact schemas. Contributor `intent_hir`, `lowered_rtl_ir`,
`structural_rtl_ir` stay bounded child delegates.

Candidate/contributor `declared_type_name`/`declared_type_spec` each emits only when
defined; check separately, no pair promised. Candidate `multi_value_assertion`
inputs use family `aggregate_enable_signal`; family `same_value_assertion` inputs
use contributor `source_enable_signal`. Both are `onehot0` metadata, without
execution proof. Replay checks current code and dated guides; deeper models
stay delegated. No source epoch reruns.
`perl/FSM/Composition/SharedDatapathCandidateBuilder.pm`,
`perl/FSM/Composition/SharedDatapathSupport.pm`.
