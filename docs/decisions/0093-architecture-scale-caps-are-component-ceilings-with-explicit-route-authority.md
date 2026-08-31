# Decision 0093: Architecture-scale caps are component ceilings with explicit route authority

- **Status:** Accepted
- **Date:** 2026-08-31
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1`
- **Refines:** [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0059](0059-vial-literal-repeat-scale-is-currently-dominated-by-expanded-actions.md), [0072](0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md)

## Context

The architecture-scale workload catalog deliberately asks each component about
its selected boundary. A complete product route is layered: parser and
SemanticIR limits precede bridge limits; bridge structure precedes execution
planning; serialized bytes may precede later count limits; backend profiles
have distinct artifact ceilings; and known structural runtime excess may
precede external-tool capture. The immutable calibration closure therefore
contains honest limit interactions, route boundaries, and preflight-dominance
records rather than pretending that every declared limit is reachable through
every route.

Those outcomes expose a policy choice. Lowering a declared count to one
observed route boundary would turn a content- and topology-dependent result
into a false universal constant. Raising an earlier layer until a later limit
became reachable would broaden qualified behavior without evidence. Rewriting
the selected workload levels would erase the evidence that revealed the
interaction. Leaving the distinction implicit would let a component defense be
misread as whole-route capacity.

## Decision

### Retain component-local hard ceilings

Every selected numeric cap remains unchanged and keeps the component that
declares it as its authority. It is a hard defense-in-depth ceiling for that
component, not a promise that every canonical route can reach it. No parser,
semantic, bridge, execution, checking, backend, runtime, transcript, result,
timeout, publication, or cleanup boundary is raised or lowered by this
selection. All catalog levels and accepted-profile bytes remain unchanged.

### Publish three distinct route facts

For every layered or dominated axis, evidence and user-facing documentation
must keep these facts separate:

1. the component-local declared ceiling;
2. the earliest authority that actually decides the evaluated route; and
3. the measured reachable route boundary when one exists.

An earlier authority is a valid result, not an error to hide. A measured route
boundary describes only the sealed route, content, topology, profile, and tool
applicability that produced it. Neither value silently replaces the component
ceiling. Diagnostics retain the real deciding family and path.

### Harden enforcement without widening behavior

The stage-specific implementation leaves move a known count check before
avoidable materialization within the same authoritative layer and retain a
terminal defense. Exact canonical byte limits remain terminal where encoding
is required to know the exact size; a sound compact preflight may reject known
excess earlier. Cross-layer dependencies are classified explicitly rather
than bypassed. Raising a lower layer or changing a selected level requires a
separate qualification and decision.

Rejection is atomic: no partial SemanticIR, bridge manifest, execution plan,
checking result, final artifact graph, public runtime result, or publication
may escape. Known excess must not start a provider or external tool. Owned
repository-volume staging is removed on success and failure.

### Keep evidence envelopes distinct from product caps

Fixture construction bounds, RAM guards, measurement IPC, immutable
publication limits, and evidence cleanup remain safety or transport envelopes.
They fail closed but do not become product capacity claims. Backend transcript,
timeout, trace, result, and public-artifact bounds remain product envelopes
under their existing profile-specific authorities.

The versioned executable policy is
`FSM::VIAL::ArchitectureScaleCapPolicy`. It enumerates every workload-catalog
axis exactly once, binds each to an authority/treatment leaf, records known
interactions and non-axis envelopes, and checks selected catalog values against
their parser, semantic, bridge, execution, and backend authorities.

## Alternatives rejected

- **Lower every declaration to the smallest observed route boundary:** rejected
  because serialized size, topology, and profile change the boundary.
- **Raise earlier layers until every later cap is reachable:** rejected because
  it widens qualified behavior without bounded-failure and resource evidence.
- **Rewrite or delete unreachable workload levels:** rejected because the
  levels are durable probes of cross-layer consistency under decision `0072`.
- **Treat every declared ceiling as public capacity:** rejected because a local
  defense does not establish an accepted whole-route operating point.

## Ordered implementation

1. `.17.4.2` hardens source, parser, and semantic enforcement;
2. `.17.4.3` hardens bridge enforcement;
3. `.17.4.4` hardens execution enforcement;
4. `.17.4.5` hardens checking-state enforcement;
5. `.17.4.6` hardens profile-specific backend enforcement;
6. `.17.4.7` hardens runtime/result/tool envelopes; and
7. `.17.4.8` proves cross-family consistency, atomicity, and cleanup.

Each leaf preserves accepted identities and commits its own focused boundary,
adjacent-excess, diagnostic, no-partial-output, and cleanup evidence before the
next leaf activates.

## Claim verification

- **Re-derive:** enumerate the live workload catalog; join every axis to the
  versioned policy; and compare selected limits to the parser, SemanticBuilder,
  HIAL-to-VIAL bridge, execution, backend-emission, and runtime authorities.
- **Falsify:** remove an axis, change a selected level, mutate a declared value,
  group, interaction, profile, or envelope, and require the policy assertion to
  reject the contradiction before any product route executes.
- **Durability:** retain the versioned module, focused t1685 contract, this
  decision, task-tree evidence, Knowledge Map card, mdBook explanation, claim
  inventory, and work-unit Git history.

## Consequences and nonclaims

- Architecture-scale results can state exactly why a later cap was not reached
  without understating the later component's independent defense.
- Later enforcement work has one closed policy inventory and cannot silently
  raise, lower, or relabel limits.
- This selection changes no accepted source, IR, manifest, plan, artifact,
  trace, result, support, performance budget, capacity, or public API.
- Whole-product “big” and “really big” qualification remain unclaimed.
