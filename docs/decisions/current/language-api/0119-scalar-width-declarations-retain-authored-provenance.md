---
id: isf-authored-scalar-width-provenance
title: Scalar width declarations retain authored provenance
answers:
  - "where do authored ISF scalar width dependencies disappear?"
  - "how will private ISF width declarations distinguish equal defaults?"
date: 2026-10-22
status: current
tags: [isf, width, parameters, lowering, provenance]
evidence: docs/audits/scalar-width-foundation-20261022.json.gz; docs/audits/scalar-width-foundation-20261022.txt; docs/audits/scalar-width-foundation-verify-20261022.py; docs/tasks/ISF-REDUCTION-DELIVERY.md
reverify: python3 -B docs/audits/scalar-width-foundation-verify-20261022.py
---
# 0119 — Scalar width declarations retain authored provenance

- Type: private declaration and lowering contract
- Status: selected; implementation pending
- Owner: `ISF-REDUCTION-DELIVERY.2.1`

## Context

Decision 0117 requires authored width dependencies to survive independently of
resolved defaults. The source-only audit locates their first loss in ISF parser
width finalizers. Parameter, alias, distinct equal-default parameter and constant
references become numbers. LoweringIR projects those numbers, then IAL0 emits
them. Named types already retain their own reference/specification. A transaction
parameter-use set does not associate each port with its source token.

Actual library use-site overrides remain in generated tops while child shapes
keep their defaults. This is the existing specialization backlog, not a newly
qualified implementation. Derived arithmetic remains refused at actor parameter
admission. Audit/native/private products alone cannot establish generic HDL.

## Decision

Capture a private `_width_declaration` at the existing successful parser width
resolution branch. Preserve its original token, source kind and lexical owner;
keep the resolved number in the existing `width` field. Distinguish actor
parameters, actor constants, package constants and transaction parameters from
their actual resolution branch, preserving local shadowing and authored aliases.
Do not infer dependencies from equal numbers. Explicit literals and implicit
one-bit declarations do not acquire parameter provenance. Named types retain
their existing separate representation. Detach token data before inspection.

Reuse existing static/alias resolution. Derived arithmetic must share public
IAL0 integer-expression semantics while retaining the ISF contract's earlier-
declaration requirement; do not introduce an independent evaluator. IAL0's
acyclic out-of-order parameter graph is not permission to widen ISF ordering.

Qualify parser preservation first, then physical preparation/IR/carrier
associations, then detached successful native/API/newline MCP reports and
schema applicability. Public numbers describe the selected environment.
Generic HDL, re-specialization, reset/constant sizing and external legality
retain separate required owners under `.3`, `.4` and SEM `.32.3`.

## Consequences and evidence

The initial slice changes no source admission, carrier or public report schema.
Every later propagation boundary needs an independent declaration oracle and
caller/result isolation; transport agreement alone cannot establish provenance.
The audit's literal source/scope/carrier oracles and hostile association records
qualify its observed baseline, not future implementation. Exact selected Git
source joins, tracked producer/receipt/verifier and missing footprint/raw-stream/
HDL/API legs are recorded in the companion audit. Required reductions and
publication remain open until their actual behavior is qualified.

This bounded record owns the new fact/question without growing the rollover-
debt Knowledge Map card collection or the saturated decision 0117. Both original
records remain byte-exact; no previous question or fact is removed.
