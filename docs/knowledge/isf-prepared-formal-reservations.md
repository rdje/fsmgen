---
id: isf-prepared-formal-reservations
title: Checked prepared reservation inputs retain explicit module scopes
answers:
  - "how are missing prepared formal reservation categories rejected?"
  - "does the checked reservation collector prove final emitted completeness?"
  - "how are parent child and domain reservation scopes represented?"
date: 2026-09-27
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

The result retains the same conservative reserved_names/origins union as the
previous complete product selection, plus deterministic scopes with typed
identities. Ordinary parents use actor_module/actor/parent; independently emitted
domains use actor_domain/actor/domain/parent; child scopes append child and the
actual child product key instead of parent. Multi-domain monolithic preparation
is not advertised as an emitted module. Each scope has its own detached name and
JSON-pointer provenance inventory; the union can conservatively reserve names
across scopes without merging their physical ownership.

T1959 qualifies every missing or malformed top-level category, unknown producers,
missing live or child products, erased/misidentified domains, cycles, reordered
input hashes, detached snapshots, source storage/formal shadows, real FIFO
children, static-zero exclusions and a single declared domain. T1957 now consumes
this checked collector in its actual projected-domain integration cases.

This is an input schema and membership contract. It does not authenticate
arbitrarily edited product contents, prove later producer coverage, or replace
canonical executable validation. Final declaration coverage and missing-reservation
falsification remain the next task leaf; production does not automatically rename
formals. The generic partial collector remains available for individual producer
qualification. Existing controller, local-call and runtime limitations remain.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.1.
