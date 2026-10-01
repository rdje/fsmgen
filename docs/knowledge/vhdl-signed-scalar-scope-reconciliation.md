---
id: vhdl-signed-scalar-scope-reconciliation
title: Signed one-bit VHDL arithmetic has bounded xor and and support
answers:
  - "why did VHDL_SCOPE contradict signed scalar support?"
  - "what qualifies the signed scalar VHDL arithmetic boundary?"
  - "which signed scalar VHDL arithmetic remains unsupported?"
date: 2026-10-01
status: current
tags: [vhdl, backend, signed, scalar, scope, reconciliation]
evidence: >-
  docs/VHDL_SCOPE.md;
  docs/book/src/14l-backends-validation-and-apis.md;
  docs/audits/vhdl-scalar-scope-reconciliation-20261001/manifest.json;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  python3 docs/audits/vhdl-scalar-scope-reconciliation-20261001/verify.py
---

Bounded signed-scalar addition/subtraction/multiplication and RHS chains use
one-bit `std_logic` bit-pattern logic: addition/subtraction use `xor`, and
multiplication uses `and`. Operand and target signedness must match. Signed
scalar division/modulo and mixed-sign scalar arithmetic remain fail-closed.

The historical blanket refusal was introduced at `0f31a983ffaafb606b41e1e42c965523279f37db`.
Support shipped at `b4033eb3f62856b8d60d3554475883e13490dfcd`, which updated
other scope bullets while leaving the separate refusal and vector-only deferral.
SEM `.60.4.3.2.5.5.3.1` reconciles those two statements against exact history
and current pipeline/facade source-generation controls. The sealed verifier
protects every other scope byte and rejects stale/operator/profile substitutions.

Declared record inputs retain their separate VHDL profile refusal. Text emission
does not qualify executable VHDL (decision 0023). The audit's tool lookups are a
capture-bound PATH observation, not a global installation claim.

The bounded historical partition at `docs/knowledge/direct-vhdl-scaffold.md`
remains byte-exact; this separate fact owns the new reconciliation evidence.
Related: [[direct-vhdl-scaffold]], [[isf-record-input-backend-profiles]].
