---
id: normalized-semantic-composition-shared-datapath-alias-schema
title: Normalized semantic composition advertises shared-datapath candidate alias schemas
answers:
  - "where are semantic.composition shared_datapath_candidates entry keys advertised?"
  - "what keys are in semantic.composition.shared_datapath_candidates entries?"
  - "does semantic.composition.shared_datapath_candidates reuse lowered-RTL shared-datapath schemas?"
  - "where are composition shared-datapath candidate alias keys advertised?"
  - "does bound_connection_expr_keys fully describe compound shared-datapath bindings?"
  - "where are shared-datapath grouped lookups?"
date: 2026-10-25
status: current
tags: [normalized-semantic-json, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_shared_closure.py docs/audits/mcp-api-reference-20261023/shared-closure-qualified.json.gz --current-contracts
---

`FSM::Support::NormalizedSemanticCompositionContract` aliases
`semantic.composition.shared_datapath_candidates[]` to lowered candidate/optional
type/contributor/drive-intent/RHS-enable/binding/aggregate/aggregate-contributor/
assertion helpers. Dated strict JSON audit checks root/lowered schema parity.

`bound_connection_expr_keys`: `signal_ref` `kind`/`signal_name`, not full grammar.
Public IR builder preserves `concat` nodes/operands; full-model owner:
`PERL-POD-API-REFERENCE.6.4.1`, `perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm`.
Replay: current code, dated guides/public-helper evidence; no original
source/compiler/backend rerun. Grouped maps retain ordered lists/subjects;
semantic lowered keys drop `success_`.
