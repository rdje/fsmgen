---
id: normalized-semantic-composition-shared-datapath-alias-schema
title: Normalized semantic composition advertises shared-datapath candidate alias schemas
answers:
  - "where are semantic.composition shared_datapath_candidates entry keys advertised?"
  - "what keys are in semantic.composition.shared_datapath_candidates entries?"
  - "does semantic.composition.shared_datapath_candidates reuse lowered-RTL shared-datapath schemas?"
  - "where are composition shared-datapath candidate alias keys advertised?"
  - "does bound_connection_expr_keys fully describe compound shared-datapath bindings?"
date: 2026-10-24
status: current
tags: [normalized-semantic-json, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_shared_drive.py --current-contracts
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded aliases
at `semantic.composition.shared_datapath_candidates[]`, reusing lowered
candidate/optional declared-type/contributor/drive-intent/nested RHS-enable/
bound-connection/aggregate-enable/aggregate-contributor/assertion helpers.
The recorded strict composition semantic JSON runtime audit checks matching
root/lowered schemas, avoiding divergent duplicate schemas.

`bound_connection_expr_keys` lists `signal_ref`'s `kind`/`signal_name`; the public
IR builder preserves `concat` operands/nodes. This is not complete expression
grammar. Full kind-model owner: `PERL-POD-API-REFERENCE.6.4.1`. Expression source:
`perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm`.
Replay uses current code, dated guides and public-helper evidence, without
original source/compiler/backend reruns.
