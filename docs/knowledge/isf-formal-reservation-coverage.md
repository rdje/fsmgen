---
id: isf-formal-reservation-coverage
title: Detached final module guard checks prepared reservations and private formal ownership
answers:
  - "how does final formal reservation coverage detect an omitted producer name?"
  - "which actual module scopes are checked before formal rewrite integration?"
  - "does reservation coverage enable automatic production formal renaming?"
date: 2026-10-03
status: current
tags: [isf, formals, reservations, declarations, scope, ownership]
evidence: perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm; perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm; t/1960-isf-formal-reservation-coverage.t; t/1957-isf-formal-domain-reservation-integration.t
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/reservation-coverage-source-copy-checks-20261003/reverify.py
---

FormalReservationCoverage::verify takes original prepared source, its canonical
FormalIdentityPlan and actual parent/domain LoweringIR modules keyed by physical
actor_name. It rebuilds checked reservations and allocation, rejects stale plans,
requires exactly the parent/emitted domains and prepared generated/reusable
children with matching physical identities, and refuses nested child scopes.

Each scope checks signal maps, ports, constants, parameters, states, DTs,
internal/storage/system declarations, enum/type tokens and implicit assignment
targets against its own inventory. Only live direct parent/domain transaction
formals may extend it with planned names; they retain counters/signal_widths,
transaction_port ownership and separation from fixed ports/storage/blocks/types.
Children receive no parent allowance. Returned scope identities are detached.

T1960 checks public modules/carriers, removes wait
reservations while preserving allocation, and injects late register/assignment,
module membership/identity/nesting, stale-plan and formal width/role/block-alias
controls. Its fixtures include case-fold conflicts, permutations, generated/FIFO/
ATL/vector/batch children, storage, rule payload and monitor formals. T1957 adds
combined domain/resource/storage/completion/crossing cases; see
[generated-domain identities](isf-generated-domain-identities.md).

The [profile](../audits/reservation-coverage-helper-causes-20261003/scope.txt)
binds native calls/copies; API inputs preserve kinds/sharing. [Actor-copy qualification](../audits/reservation-coverage-source-copies-20261003/scope.txt)
binds lost numeric FIFO indexes/binding widths and ATL route width to source.
Pure actor copies retain kinds/sharing; complete lowering/carriers/scope results
agree. The [cause repair](../audits/reservation-coverage-cause-repair-20261003/scope.txt)
uses complete causes and saved native errors; wrong-cause, exact-prior and actual
declaration-guard bypass controls qualify.
[Module join](../audits/reservation-coverage-module-join-20261003/scope.txt) closes field cohorts and FIFO/vector propagation.
[Snapshot capture](../audits/reservation-coverage-snapshot-capture-20261003/scope.txt) binds remaining copies.
[Ordinary fields](../audits/reservation-coverage-snapshot-normal-fields-20261003/scope.txt) qualify; rebuilt-input/real controls precede P2 .13.
Constructors/moved-root stay cold.

This guard checks final declarations at the prepared ISF-to-FSM boundary. It does not replace source or executable admission,
prove arbitrary edited IR, or cover new producer/emitter boundaries
without extending qualification. [Production formal lowering](isf-production-formal-scope.md) now invokes this
guard after actual module construction and before emission, with authored
report provenance restored in a detached view. Independent controller/local-call runtime
qualification remains separately owned.
Private formals must stay in explicit_internal_signals; width/role alone can
infer an unassigned read as a public input. T1963 removes that classification
and checks private-formal exclusion from public ports.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.2.
