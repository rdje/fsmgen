# VIAL v2 lifecycle-control family

Date: 2026-09-04
Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1`
Status: semantic and source contract selected; implementation unavailable

## Outcome and boundary

Revision 1 of `lifecycle_control` describes how one fixture becomes ready,
starts stimulus, completes selected scenarios, drains owned work, shuts down,
and finalizes. It also owns bounded background-service lifetime, logical-cycle
deadlines, and fail-closed cleanup. It does not describe a simulator schedule,
target-language process, or verification-methodology API.

This is a selection contract. The family registry already reserves
`lifecycle_control@1`, capability `vial.family.lifecycle_control.v1`, and the
effects listed below, but every functional and backend maturity remains
`unavailable`. Until `.19.2.2` implements the closed grammar and semantic
records, a nonempty family block fails `VIAL_FAMILY_UNSUPPORTED` and returns no
partial SemanticIR. This document does not change accepted source or advertise
backend, runtime, result, parity, or support.

The common family envelope and source-version rules remain authoritative in
[the semantic-family contract](semantic-family-envelope-and-registry.md) and
[the v2 source contract](source-semantic-ir-v2.md).

## Closed source grammar

One source node controls one fixture. A package may declare at most one
lifecycle for a fixture. References are package-local unqualified identifiers;
the fixture and domain may be declared later in the package.

```text
LIFECYCLE := (lifecycle NAME
  (fixture FIXTURE)
  (domain DOMAIN)
  (dependencies DEPENDENCY*)
  READINESS
  (services SERVICE*)
  STIMULUS_START
  COMPLETION
  DRAIN
  SHUTDOWN
  FINALIZE
  (deadlines DEADLINE+)
  FAILURE)

DEPENDENCY := (dependency NAME (when CONDITION))
READINESS := (readiness NAME REQUIRES?)
SERVICE := (service NAME
  (target fixture_background)
  START_REQUIRES? READY_REQUIRES? QUIESCENT_REQUIRES? STOP_REQUIRES?
  CANCELLATION?)
STIMULUS_START := (stimulus_start NAME REQUIRES?)
COMPLETION := (completion NAME REQUIRES?)
DRAIN := (drain NAME REQUIRES?)
SHUTDOWN := (shutdown NAME REQUIRES?)
FINALIZE := (finalize NAME REQUIRES?)

REQUIRES := (requires CONDITION)
START_REQUIRES := (start_requires CONDITION)
READY_REQUIRES := (ready_requires CONDITION)
QUIESCENT_REQUIRES := (quiescent_requires CONDITION)
STOP_REQUIRES := (stop_requires CONDITION)
CANCELLATION := (cancellation cooperative)

DEADLINE := (deadline NAME
  (from MILESTONE)
  (until MILESTONE)
  (within POSITIVE_INTEGER))

FAILURE := (failure NAME
  DISPOSITION? CLEANUP? CLEANUP_WITHIN? DIAGNOSTICS?)
DISPOSITION := (disposition fail)
CLEANUP := (cleanup finalize)
CLEANUP_WITHIN := (cleanup_within POSITIVE_INTEGER)
DIAGNOSTICS := (diagnostics first | all)
```

Every clause is ordered exactly as shown. An unknown, repeated, reordered, or
wrong-arity clause is an error. `fixture_background` is the revision-1
target-neutral aggregate of the fixture's selected observation, model,
scoreboard, coverage, and result-collection work; it excludes scenario
stimulus. A service is a lifetime policy for that aggregate, not a service body
or a generated component. Revision 1 admits zero or one such service. The
compiler creates no service when the form is absent and rejects an explicitly
authored service whose aggregate would be empty.

### Conditions and milestones

The condition algebra is deliberately monotone and has no negation, arbitrary
expression, callback, or target escape:

```text
CONDITION := (configured)
           | (reset_inactive DOMAIN)
           | (dependency_satisfied DEPENDENCY)
           | (service_started SERVICE)
           | (service_ready SERVICE)
           | (service_quiescent SERVICE)
           | (service_stopped SERVICE)
           | (lifecycle_point POINT)
           | (scenarios_terminal)
           | (transactions_terminal)
           | (scoreboards_empty)
           | (all CONDITION+)

MILESTONE := (lifecycle_entered)
           | (dependency_satisfied DEPENDENCY)
           | (service_started SERVICE)
           | (service_ready SERVICE)
           | (service_quiescent SERVICE)
           | (service_stopped SERVICE)
           | (lifecycle_point POINT)

POINT := readiness, stimulus-start, completion, drain, shutdown, or finalize ID
```

`configured` means construction, typed configuration, and compiler-owned
connections succeeded before lifecycle entry. `reset_inactive` reads the
named HIAL-reviewed fixture domain. `scenarios_terminal` covers exactly the
scenarios selected in the execution request. `transactions_terminal` covers
every transaction handle started by those scenarios. `scoreboards_empty`
covers every scoped expected/actual queue. A satisfied dependency, reached
point, or reached service milestone is latched and never becomes false.

All identifiers declared by one lifecycle—including generated service
milestones—share one uniqueness namespace. References cannot cross lifecycle
or fixture scope. Forward references are permitted only when the complete
dependency graph remains acyclic.

## Normal and terse projections

The family block itself has one spelling in both source styles. Normal source
places it inside `intents`; terse source removes only that outer wrapper, as
required by the v2 source contract. Family-specific aliases are not accepted.

<!-- lifecycle-normal-example:start -->
```vial
(intents
  (family lifecycle_control
    (revision 1)
    (lifecycle fixture_flow
      (fixture base_output_arbitration)
      (domain bus)
      (dependencies
        (dependency configured_gate (when (configured)))
        (dependency reset_gate (when (reset_inactive bus))))
      (readiness ready)
      (services
        (service background
          (target fixture_background)))
      (stimulus_start stimulus)
      (completion complete)
      (drain drained)
      (shutdown stopped)
      (finalize finalized)
      (deadlines
        (deadline total
          (from (lifecycle_entered))
          (until (lifecycle_point finalized))
          (within 1024))
        (deadline startup
          (from (lifecycle_entered))
          (until (lifecycle_point ready))
          (within 32)))
      (failure lifecycle_failure))))
```
<!-- lifecycle-normal-example:end -->

The same family block in terse package order is:

<!-- lifecycle-terse-example:start -->
```vial
(family lifecycle_control
  (revision 1)
  (lifecycle fixture_flow
    (fixture base_output_arbitration)
    (domain bus)
    (dependencies
      (dependency configured_gate (when (configured)))
      (dependency reset_gate (when (reset_inactive bus))))
    (readiness ready)
    (services
      (service background
        (target fixture_background)))
    (stimulus_start stimulus)
    (completion complete)
    (drain drained)
    (shutdown stopped)
    (finalize finalized)
    (deadlines
      (deadline total
        (from (lifecycle_entered))
        (until (lifecycle_point finalized))
        (within 1024))
      (deadline startup
        (from (lifecycle_entered))
        (until (lifecycle_point ready))
        (within 32)))
    (failure lifecycle_failure)))
```
<!-- lifecycle-terse-example:end -->

These are selected insertable fragments, not currently runnable examples. The
normal fragment's family form and the terse fragment are byte-identical after
removing the normal-only `intents` wrapper. Once implemented, formatting either
style must reparse to one `fsmgen.vial_semantic_projection.v2` digest.

## Intrinsic order and defaults

An optional `requires` clause adds an AND condition; it never replaces the
intrinsic prerequisites. Omitted clauses normalize to these exact facts:

| Record or milestone | Intrinsic prerequisite / default |
| --- | --- |
| lifecycle entry | fixture is configured; logical coordination domain is bound |
| dependency | its authored `when` condition |
| service start | configured and every dependency satisfied |
| service ready | its own start committed |
| readiness | every dependency satisfied and every service ready |
| stimulus start | readiness reached |
| completion | stimulus started and every selected scenario terminal |
| service quiescent | completion reached, transactions terminal, and scoreboards empty |
| drain | completion reached, transactions terminal, scoreboards empty, and every service quiescent |
| shutdown | drain reached |
| service stop | shutdown reached |
| finalize | shutdown reached and every service stopped |
| service cancellation | `cooperative` |
| failure disposition | `fail` |
| failure cleanup | `finalize` |
| failure cleanup bound | 256 coordination-domain cycles |
| failure diagnostics | `all`, in semantic-rank order |

The mandatory chain cannot be reordered or weakened. Extra conditions can
delay a point but cannot make it precede its intrinsic predecessor. Duplicate
or cyclic conditions fail before binding. Construction and configuration are
compiler preconditions, not authored lifecycle records.

At each coordination-domain `check` seam, the controller evaluates eligible
conditions against committed facts, then commits newly reachable milestones
in topological rank, source rank, and semantic-ID order. A later-ranked point
may observe an earlier point reached at the same check seam. This fixed-point
step is the only zero-cycle progression; simulator wake order has no meaning.

## Typed semantic expansion

The compact `lifecycle` form expands one common
`fsmgen.vial_semantic_family.v2` node for every dependency, service, lifecycle
point, deadline, and failure record. Each node retains its own source span and
shares the fixture scope, coordination-domain order, and lifecycle identity.
The node kinds and effects are exact:

| Node kind | Result meaning | Declared effect |
| --- | --- | --- |
| `dependency` | pending or satisfied condition | none |
| `readiness` | fixture can admit stimulus | `ready` |
| `service` | started/ready/quiescent/stopped milestones | `service_start`, `service_stop` |
| `stimulus_start` | selected scenarios may begin | `stimulus_start` |
| `completion` | every selected scenario is terminal | `complete` |
| `drain` | owned transaction/checking work is settled | `drain` |
| `shutdown` | no new fixture work may begin | `shutdown` |
| `finalize` | semantic results are sealed | `finalize` |
| `deadline` | met, expired, or cancelled interval | `deadline` |
| `failure` | first cause, cleanup, and terminal disposition | `failure` |

Every payload uses schema `fsmgen.vial_lifecycle_control.v1` and contains
exactly `schema`, `schema_version`, `lifecycle_id`, `fixture_id`, `domain_id`,
`record_kind`, `record_id`, `condition`, `intrinsic_after`, `additional_after`,
and `detail`. Keys irrelevant to a node are represented by null or empty typed
values, not omitted or repurposed. The common envelope owns scope, lifetime,
order, effects, failure/result contracts, semantic path, and source span.

`condition` contains the dependency or point's fully expanded conjunction;
`intrinsic_after` and `additional_after` are ordered semantic-ID arrays.
`detail` is a closed record selected by `record_kind`:

| Record kind | Exact `detail` keys |
| --- | --- |
| `dependency`, lifecycle point | none; represented as an empty record |
| `service` | `target`, `cancellation`, `start_condition`, `ready_condition`, `quiescent_condition`, `stop_condition` |
| `deadline` | `from`, `until`, `max_cycles`, `last_cycle_inclusive` |
| `failure` | `disposition`, `cleanup`, `cleanup_max_cycles`, `diagnostics` |

Normalized condition records contain exactly `kind`, `reference_id`,
`domain_id`, and `operands`; unused scalar references are null and leaf
operands are empty. `last_cycle_inclusive` is true. No raw source node or
backend value survives in any payload.

Execution and plan preserve the nodes and add only typed bindings, operation
IDs, required capabilities, and cumulative source maps. The complete result
adds one `fsmgen.vial_lifecycle_result.v1` per lifecycle with exactly:

```text
schema, schema_version, lifecycle_id, fixture_id, domain_id, status
entered_at, dependency_results, readiness_result, service_results
stimulus_start_result, completion_result, drain_result, shutdown_result
finalize_result, deadline_results, failure_result, source_map
```

Status is `pass`, `fail`, `timeout`, `cancelled`, or `error`. Times are VIAL
logical `(domain, cycle, phase, ordinal)` records. Target timestamps, process
IDs, hierarchy handles, and scheduler-region names are evidence-only and never
enter this semantic result.

The family always requires `vial.family.lifecycle_control.v1` and
`vial.family.lifecycle_control.deadline.v1`. The latter is mandatory because
every lifecycle carries a full-lifetime deadline. Actual effects are derived
from present node kinds and remain within the registry's reserved vocabulary:
`complete`, `deadline`, `drain`, `failure`, `finalize`, `ready`,
`service_start`, `service_stop`, `shutdown`, and `stimulus_start`.

## Deadline and failure semantics

Every lifecycle must contain exactly one full deadline from
`lifecycle_entered` until its finalize point. Additional intervals may start
and end only at monotone milestones in the same lifecycle. All counts use the
declared coordination domain and the inherited range 1 through 2,147,483,647.
If a start milestone commits at cycle C, an interval of N cycles accepts its
end milestone through check seam C + N - 1. Deadline checks run after eligible
milestones at that seam, so an end reached on the last included cycle passes.

The first expired deadline or failed service becomes the primary cause. Normal
stimulus stops, active scenarios receive cooperative cancellation, service
stop is requested, and shutdown/finalization proceed under the failure
record's independent `cleanup_within` bound. The terminal status cannot return
to pass. Cleanup expiry seals `error`, preserves every reached/unreached
milestone and residue, and delegates only host-process teardown to the already
bounded backend supervisor. It does not wait indefinitely or publish false
success.

## Finite bounds

These family limits are checked before allocating expanded semantic records:

| Resource | Limit |
| --- | ---: |
| lifecycle programs per package | 1,024 and no more than fixture count |
| lifecycle programs per fixture | 1 |
| dependency records per lifecycle | 64 |
| service records per lifecycle | 1 in revision 1 |
| deadline records per lifecycle | 64 |
| expanded records per lifecycle | 256 |
| expanded lifecycle records per connected catalog | 65,536 |
| condition terms per lifecycle | 256 |
| condition nesting depth | 16 |
| references in one `all` condition | 64 |
| logical cycles in a deadline or cleanup bound | 2,147,483,647 |
| identifier component | inherited 128-byte lexical limit |

The common 4,096-node family-block and 65,536 source-family-node catalog
ceilings remain independent. The first reached limit owns the deterministic
diagnostic. None of these safety limits is a scale or support claim.

## Diagnostics and atomic failure

| Condition | Stable diagnostic |
| --- | --- |
| malformed, reordered, unknown, or target-shaped source clause | `VIAL_PARSE_ERROR` |
| duplicate identity, illegal reference, missing full deadline, cycle, or intrinsic-order contradiction | `VIAL_SEMANTIC_ERROR` |
| family or inherited bound exceeded | `VIAL_LIMIT_ERROR` |
| fixture/domain/background-service binding is unavailable | `VIAL_BIND_REFERENCE_ERROR` |
| logical deadline expires | `VIAL_LIFECYCLE_DEADLINE_EXPIRED` |
| background service cannot start, become ready/quiescent, or stop | `VIAL_LIFECYCLE_SERVICE_ERROR` |
| bounded cleanup reaches finalization with unsettled owned work | `VIAL_LIFECYCLE_DRAIN_INCOMPLETE` |
| bounded failure finalization expires | `VIAL_LIFECYCLE_CLEANUP_TIMEOUT` |

Source diagnostics use `fsmgen.vial_diagnostic.v2`. Runtime lifecycle failures
are ordered by logical time, semantic rank, and semantic ID; later independent
causes become notes or failure-result entries according to `diagnostics`.
Every failure is atomic at its stage: no partial SemanticIR, binding, plan,
artifact graph, or success result is returned. The four lifecycle-specific
codes become public only with the implementing/result leaves; selection alone
does not add them to capability discovery.

## Backend-private realization and nonclaims

Portable SystemVerilog and VHDL routes will lower the typed graph to one
bounded static controller. A native UVM route may map construction,
configuration, readiness, execution, drain, and finalization to its phase
machinery and one root-test-owned objection. Those names and mechanisms are
mapping evidence only. They are forbidden in authored family forms and cannot
alter logical order, deadline inclusivity, cleanup, or normalized results.

This selection does not qualify any of those mappings. It does not implement
source parsing, SemanticIR, binding, planning, emission, compilation, runtime,
results, parity, mixed-language behavior, provider access, public capability,
support, scale, or HIAL behavior. Rollback removes this part, its landing/book
links, Knowledge Card, and selection evidence; the v2 foundation and immutable
v1 contract remain unchanged.
