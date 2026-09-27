---
id: isf-formal-reservation-coverage
title: Detached final module guard checks prepared reservations and private formal ownership
answers:
  - "how does final formal reservation coverage detect an omitted producer name?"
  - "which actual module scopes are checked before formal rewrite integration?"
  - "does reservation coverage enable automatic production formal renaming?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, declarations, scope, ownership]
evidence: perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm; perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm; t/1960-isf-formal-reservation-coverage.t; t/1957-isf-formal-domain-reservation-integration.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1960-isf-formal-reservation-coverage.t t/1957-isf-formal-domain-reservation-integration.t t/1959-isf-prepared-formal-reservations.t
---

FormalReservationCoverage::verify accepts original prepared source, its canonical
complete FormalIdentityPlan, and actual admitted parent/domain LoweringIR modules
keyed by physical actor_name. It rebuilds the checked input inventory and allocation
plan, rejecting stale or incomplete allocations. The module set must match the
ordinary parent or actual independently emitted domains. Each parent's children
must match the prepared generated/reusable child set and physical child identity;
unplanned nested child modules fail closed.

Every scope checks actual signal maps, ports, constants, parameters, states, DTs,
internal and storage declarations, system signals, enum/type value tokens and
implicit assignment targets against its own prepared inventory. Only direct
formals belonging to a live transaction in that parent/domain may extend the
inventory with planned physical names. Each such formal must retain its width
in counters and signal_widths, its transaction_port role, and separation from
fixed ports, storage, blocks and system/type declarations. Child scopes receive
no parent-formal allowance. The verifier returns detached verified scope identities
and never modifies the prepared products, allocation or executable IR.

T1960 observes modules from actual public lowering, checks final exported carriers,
and falsifies coverage by removing every reservation for an actual dynamic-wait
helper while preserving allocation. It also injects late registers and implicit
assignment targets, missing/extra/wrong modules, nested children, stale plans,
wrong formal width/role and a block aliasing a formal. Case-folded helper conflicts,
declaration permutations, generated children, FIFO, resolved ATL/vector/batch
children, storage metadata, rule payload identity and a real monitor-helper formal
are qualified. T1957 applies the guard to its combined domain/resource/storage/
completion and crossing cases. The preceding outer-scope qualification remains
[the generated-domain identity record](isf-generated-domain-identities.md).

This detached guard establishes the final declaration check for the prepared
ISF-to-FSM module boundary. It does not replace source or executable admission,
prove arbitrary edited IR behavior, or cover new producer/emitter boundaries
without extending qualification. [Production formal lowering](isf-production-formal-scope.md) now invokes this
guard after actual module construction and before emission, with authored
report provenance restored in a detached view. Independent controller/local-call runtime
qualification remains separately owned.
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.2.
