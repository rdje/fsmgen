---
id: direct-aggregate-default-profile
title: Direct aggregate default preparation folds immutable captured subtrees
answers:
  - "which private helper prepares direct immutable aggregate defaults?"
  - "how are mutable aggregate and path defaults classified before header integration?"
date: 2026-10-27
status: current
tags: [parameters, aggregates, defaults, lowering]
evidence: perl/FSM/Backend/VerilogFamily/ParameterBindingEmitter.pm; t/2148-direct-aggregate-default-profile.t; docs/book/src/04-symbols-types-and-imports.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2148-direct-aggregate-default-profile.t t/2146-shared-scalar-binding-renderer.t t/2132-composition-scalar-binding-renderer.t
---

The direct-scope `lower_default` helper folds immutable aggregate subtrees
through ParameterValueSupport. Actual captured literal/static inputs determine
packed list/map order, leafwise operators and scalar comparisons; selected
declaration caches cannot replace that meaning. Scalar parameter roots outside
the folded subtree preserve their immediate names and ordered occurrences.

Mutable aggregate roots, member/index paths and aggregate constructors with
scalar parameter references refuse contextually. Complete unique map order,
literal static payloads, scopes and cyclic graphs are checked. Caller JSON
kinds remain unchanged. The existing scalar/composition entrypoint retains its
contract. Header integration, source/corpus/native/API/MCP admission and full
external/runtime qualification are separate successors; this helper alone
does not change emitted headers or public schemas.
