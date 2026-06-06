---
id: normalized-semantic-composition-shared-datapath-alias-schema
title: Normalized semantic composition advertises shared-datapath candidate alias schemas
answers:
  - "where are semantic.composition shared_datapath_candidates entry keys advertised?"
  - "what keys are in semantic.composition.shared_datapath_candidates entries?"
  - "does semantic.composition.shared_datapath_candidates reuse lowered-RTL shared-datapath schemas?"
  - "where are composition shared-datapath candidate alias keys advertised?"
date: 2026-06-06
status: current
tags: [normalized-semantic-json, composition, shared-datapath, public-api]
evidence: perl/FSM/Support/NormalizedSemanticCompositionContract.pm; perl/FSM/Support/NormalizedSemanticPayloadContract.pm; perl/FSM/Support/NormalizedSemanticReportContract.pm; perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm; t/333-normalized-semantic-composition-contract.t; t/330-normalized-semantic-payload-contract.t; t/311-normalized-semantic-report-contract.t; t/297-capability-manifest.t; t/354-normalized-semantic-child-runtime-contract-audit.t; t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t; t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t; docs/book/src/11-extensions-and-embedding.md; docs/book/src/14-feature-backlog.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/333-normalized-semantic-composition-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/354-normalized-semantic-child-runtime-contract-audit.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t
---

`FSM::Support::NormalizedSemanticCompositionContract` advertises bounded alias
schemas under `semantic.composition.shared_datapath_candidates[]`.

Those alias key families delegate to the already bounded lowered-RTL
`composition_shared_datapath_candidates[]` candidate, optional declared-type,
contributor, contributor drive-intent, drive-intent RHS enable-family,
bound-connection, aggregate-enable, aggregate contributor, and assertion helper
families.

Runtime coverage checks a strict composition semantic JSON export and verifies
that `semantic.composition.shared_datapath_candidates[]` matches the lowered-RTL
candidate surface instead of introducing a second divergent schema.
