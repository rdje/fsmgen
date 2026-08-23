# 0079 — VIAL plan preflight reuses one bounded random-decision transcript

- Date: 2026-08-23
- Type: verification architecture/limit enforcement
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1`
- Refines: [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0061](0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md), [0078](0078-vial-execution-total-operation-cap-precedes-graph-materialization.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1`

## Context

The clean revision-`037e56f09` execution/checking matrix atomically publishes
its first twenty-two execution profiles. The isolated
`random_attempts/limit_v1` worker then exits without a publication because its
controller correctness validation does not accept. There is no guard
termination, partial profile, family seal, full seal, or raw-stage residue.

The regression is a composition error between two individually intentional
proofs. The serialized-plan preflight streams each generated decision so a
known-excess plan can reject before retaining a decision list. An accepted
plan then calls the ordinary materializer, which generates those same
deterministic decisions again. The execution-family oracle builds the accepted
plan twice, and the measurement worker invokes that complete oracle twice.
Consequently one controller bind-plan stage performs eight random-generation
passes.

A direct run under the unchanged repository guard reaches the exact accepted
attempt 999,999 in 61.094573 seconds. The eight-pass call graph therefore has
a 488.756584-second generator-only lower bound before parsing, bridge work,
plan construction, canonical comparison, or artifact materialization. It
cannot fit the unchanged 300-second stage ceiling. The previous revision's
sealed profile proves the count, algorithm, plan, and controller contract can
fit when accepted materialization does not repeat the preflight generation.

## Decision

1. Preserve the random algorithm, one-million-attempt limit, accepted attempt,
   generated and replayed decisions, plan schema/bytes/identity, limit
   diagnostics, controller rerun count, timeouts, guards, and all support,
   performance-budget, capacity, and reached-boundary nonclaims.
2. Generate or replay-validate each projected decision exactly once per
   `ExecutionBuilder` invocation. Canonical serialized-plan projection remains
   independent of final ExecutionIR and report materialization; it must not
   trust a caller-supplied decision, plan, or transcript.
3. While projecting, retain only a private canonical byte transcript of the
   projected decision records. Frame every record with a fixed-width length,
   keep the representation scalar rather than a Perl decision/source-map
   graph, and bound it by the serialized-plan cap plus fixed framing for at
   most the already-enforced random-occurrence limit. If canonical decision
   bytes cross the plan cap, discard the incomplete transcript but continue
   generation or replay validation so earlier random/replay authority remains
   visible.
4. Apply the unchanged serialized-plan cap to the complete projection before
   any final decision list, random source-map suffix, ExecutionIR, or
   ExecutionReport is allocated. A plan that passes this cap must have a
   complete transcript; an incomplete accepted transcript is an internal
   consistency failure.
5. Materialization walks the independently reconstructed expectation sequence,
   consumes exactly one framed record per occurrence, validates canonical
   framing, schema, ordering, identity, value, range, constraint, attempt, and
   origin, and rejects truncation, extra records, or trailing bytes. Only then
   may it allocate the final decision list, source maps, and scenario links.
   It must not call the random generator again.
6. Retain the exact terminal canonical serialization, projection-equality
   assertion, and terminal byte cap as defense in depth. Independent builder,
   execution-family, and controller reruns remain unchanged and must reproduce
   byte-identical plans.
7. Implementation evidence must include a product-level RED/GREEN call-count
   witness, transcript corruption and saturation negatives, the exact
   million-attempt adapter below its unchanged timeout, the 8,440/8,441 and
   32,768 occurrence routes, strict replay/exhaustion precedence, and a fresh
   complete matrix from one clean repaired revision.

## Consequences

- Expensive deterministic choice search is performed once per builder call,
  while independent builder and controller reruns still test determinism.
- Known-excess plans still allocate no decision list, source-map suffix,
  ExecutionIR, or report. The only reusable state is a closed bounded scalar
  transcript that is discarded before the limit rejection returns.
- Accepted plans retain exact bytes and identities but no longer pay an
  avoidable second random-search pass inside the same builder invocation.
- The revision-`037e56f09` prefix remains immutable evidence. A repaired
  revision must earn new profile and aggregate seals rather than relabel or
  mix it.

## Evidence state at selection

The re-derivation leg is the exact call graph plus the guarded 61.094573-second
primitive run. The falsification leg excludes guard termination, publication
collision, retained coordinator state, and random-contract drift: the guard
stays below its cutoff, the publisher withholds profile 23 atomically, the
tree is clean, and the same plan contract is sealed at revision `e4b95dbd`.
This decision, its task leaf, the mdBook status, and the Knowledge Map provide
the durability leg. Transcript implementation, corruption tests, exact
adapter acceptance, and fresh matrix closure are explicitly missing until the
active implementation owner earns them.
