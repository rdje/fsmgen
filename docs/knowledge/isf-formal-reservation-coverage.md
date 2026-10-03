---
id: isf-formal-reservation-coverage
title: Detached final module guard checks prepared reservations and private formal ownership
answers:
  - "how does final formal reservation coverage detect an omitted producer name?"
  - "which actual module scopes are checked before formal rewrite integration?"
  - "does reservation coverage enable automatic production formal renaming?"
  - "what qualifies T1960 copy kinds, plain sharing and native marker identity?"
  - "where is the coverage historical context?"
date: 2026-10-04
status: current
tags: [isf, formals, reservations, declarations, scope, ownership]
evidence: perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm; perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm; t/1960-isf-formal-reservation-coverage.t; t/1957-isf-formal-domain-reservation-integration.t
reverify: scripts/run_with_ram_guard.sh -- python3 -B docs/audits/reservation-coverage-source-copy-checks-20261003/reverify.py
---

FormalReservationCoverage::verify consumes original prepared source, canonical
FormalIdentityPlan and actual parent/domain LoweringIR modules keyed by physical
actor_name. It rebuilds reservations/allocation, rejects stale plans, requires
exact parent/emitted domains and prepared generated/reusable children with
physical identities; nested child scopes refuse.

Each scope checks signal maps, ports, constants, parameters, states, DTs,
internal/storage/system declarations, enum/type tokens and implicit assignment
targets against own inventory. Only live direct parent/domain transaction
formals extend it with planned names; they retain counters/signal_widths,
transaction_port ownership and separation from fixed ports/storage/blocks/types.
Children receive no parent allowance. Returned scope identities detach.

T1960 checks public modules/carriers and producer, module membership/identity/
nesting, stale-plan and formal width/role/block-alias refusals, with generated/
FIFO/ATL/vector/batch, storage/rule/monitor fixtures. T1957 adds
combined domain/resource/storage/completion/crossing cases; see
[generated-domain identities](isf-generated-domain-identities.md).

The [profile](../audits/reservation-coverage-helper-causes-20261003/scope.txt)
binds native calls/copies; API inputs preserve kinds/sharing. [Actor qualification](../audits/reservation-coverage-source-copies-20261003/scope.txt)
binds lost numeric FIFO indexes/binding widths and ATL route width to source.
Pure actor copies retain kinds/sharing and ordinary products. The [cause repair](../audits/reservation-coverage-cause-repair-20261003/scope.txt)
uses complete causes and saved native errors; wrong-cause, exact-prior and actual
declaration-guard bypass controls qualify.
[Module join](../audits/reservation-coverage-module-join-20261003/scope.txt) closes field cohorts and FIFO/vector propagation.
[Snapshot capture](../audits/reservation-coverage-snapshot-capture-20261003/scope.txt) binds remaining copies.
[Copy repair](../audits/reservation-coverage-copy-repair-20261003/scope.txt) preserves kinds/sharing/isolation and native identity, with real prior/mutation controls and pinned replay.
[Repaired-source context](../audits/coverage-repair-historical-context-20261004/scope.txt) pins this proof before unrelated hot test edits; original/repaired contexts replay separately. Constructors/moved-root stay cold.

At the prepared ISF-to-FSM boundary, this guards declarations. Source/executable
admission, arbitrary edited IR and new producer/emitter boundaries need separate
qualification. [Production lowering](isf-production-formal-scope.md) calls it after
module construction before emission; authored report provenance restores in a
detached view. Controller/local-call runtime remains separately owned.
Private formals must stay in explicit_internal_signals. Width/role can infer
unassigned reads as public inputs; T1963 excludes private formals from public ports.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.3.2.
