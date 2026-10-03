---
id: isf-prepared-formal-reservations
title: Checked prepared reservation inputs retain explicit module scopes
answers:
  - "how are missing prepared formal reservation categories rejected?"
  - "does the checked reservation collector prove final emitted completeness?"
  - "how are parent child and domain reservation scopes represented?"
date: 2026-10-03
status: current
tags: [isf, formals, reservations, preparation, scope]
evidence: perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1959-isf-prepared-formal-reservations.t; t/1957-isf-formal-domain-reservation-integration.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1959-isf-prepared-formal-reservations.t t/1957-isf-formal-domain-reservation-integration.t t/1937-isf-formal-reservation-products.t
---

PreparedFormalReservations::collect accepts the complete prepare_formal_source
result. Unlike the generic partial FormalReservationInventory collector, it
requires the declared top-level product categories with their expected shapes,
including empty values, and rejects unknown fields. New producer categories
therefore require an explicit contract update rather than a suffix-based filter.
Live transaction contexts/products must agree with authored transactions after
pruning; generated child records must match membership. Domain products must
match the source partition, logical owner and actual scheduled-domain source.
Nested preparation is checked independently. Unsupported references and cycles
fail through the existing inventory traversal before scope recursion.

Results retain a conservative reserved_names/origins union and deterministic typed scopes: actor_module/actor/parent for ordinary parents, actor_domain/actor/domain/parent for emitted domains; child scopes append child/module instead of parent. Multi-domain monolithic preparation is not an emitted module. Each detached scope has JSON-pointer provenance; the union does not merge physical ownership.

T1959 exercises missing or malformed top-level category, unknown producers,
missing live or child products, erased/misidentified domains, cycles, reordered
input hashes, detached snapshots, source storage/formal shadows, real FIFO
children, static-zero exclusions and a single declared domain. T1957 now consumes
this checked collector in its actual projected-domain integration cases.

This is an input schema and membership contract. It does not authenticate
arbitrarily edited product contents, prove later producer coverage, or replace
canonical executable validation. [Final declaration coverage](isf-formal-reservation-coverage.md) now joins these
inputs to actual admitted module scopes and detects omitted declarations.
[Production formal lowering](isf-production-formal-scope.md) consumes the checked
inventory before allocating private names. The generic partial collector remains available for individual producer
qualification. Existing controller, local-call and runtime limitations remain.
[Cause diagnosis](../audits/prepared-reservation-helper-causes-20261003/scope.txt) finds real earlier/primary false matches in the test helper and adjacent cycle assertion; .2.3.12 owns immediate complete-cause repair. Collector admission remains correct. Complete source/graph and conservative scope/token models pass; wider constructors/moved-root semantics stay separately owned.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.1.
