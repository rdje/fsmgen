---
id: vial-architecture-scale-cap-policy
title: VIAL architecture-scale caps are component ceilings with explicit route authority
answers:
  - "what is the VIAL architecture scale cap policy?"
  - "are VIAL declared resource limits public capacity claims?"
  - "why does VIAL keep a cap that a canonical route cannot reach?"
  - "what happens when an earlier VIAL layer rejects before a selected limit?"
  - "does architecture scale cap hardening raise or lower existing limits?"
  - "where is the machine checked VIAL resource cap inventory?"
  - "when are VIAL execution fiber caps enforced?"
  - "how are total and simultaneous VIAL fibers counted before materialization?"
  - "when are VIAL execution profile, binding, type, and source-map caps enforced?"
  - "does VIAL recheck selected unit and domain cardinality after SemanticIR and bridge validation?"
  - "when is the VIAL execution operations-per-scenario cap enforced?"
  - "when does VIAL random-attempt exhaustion stop plan construction?"
  - "when is the VIAL serialized-plan byte cap enforced?"
  - "when are VIAL model-instance and scalar-state-cell caps enforced?"
  - "when are VIAL scoreboard-instance and aggregate-capacity caps enforced?"
  - "when are VIAL coverpoint and bin-cross aggregate caps enforced?"
date: 2026-08-31
status: current
tags: [vial, architecture-scale, limits, bounded-failure, route-authority]
evidence: >-
  docs/decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md;
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm;
  t/1685-vial-architecture-scale-cap-policy.t;
  perl/FSM/VIAL/Parser.pm;
  t/1687-vial-parser-direct-import-cap-order.t;
  t/1693-vial-parser-source-byte-cap-order.t;
  perl/FSM/VIAL/SemanticBuilder.pm;
  t/1686-vial-semantic-action-cap-order.t;
  t/1688-vial-semantic-parallel-fiber-cap-order.t;
  t/1689-vial-semantic-declaration-cap-order.t;
  t/1690-vial-semantic-scoreboard-capacity-order.t;
  t/1691-vial-semantic-cross-max-bins-order.t;
  t/1692-vial-semantic-type-shape-cap-order.t;
  perl/FSM/HIAL/VIALBridge/Builder.pm;
  t/1694-hial-vial-bridge-configuration-cap-order.t;
  t/1695-hial-vial-bridge-endpoint-cap-order.t;
  t/1696-hial-vial-bridge-observation-cap-order.t;
  t/1697-hial-vial-bridge-probe-cap-order.t;
  t/1698-hial-vial-bridge-type-cap-order.t;
  t/1699-hial-vial-bridge-transaction-cap-order.t;
  t/1700-hial-vial-bridge-event-cap-order.t;
  t/1701-hial-vial-bridge-residue-cap-order.t;
  t/1702-hial-vial-bridge-backend-binding-cap-order.t;
  t/1703-hial-vial-bridge-source-map-cap-order.t;
  t/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t;
  perl/FSM/VIAL/ExecutionBuilder.pm;
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t;
  t/1625-vial-architecture-scale-execution-total-fiber-limit.t;
  t/1705-vial-execution-selected-domain-cap-order.t;
  t/1706-vial-execution-operation-cardinality-cap-order.t;
  t/1707-vial-execution-type-cap-order.t;
  t/1708-vial-execution-source-map-cap-order.t;
  t/1709-vial-execution-binding-cardinality-preflight.t;
  t/1710-vial-execution-random-attempt-authority.t;
  t/1634-vial-architecture-scale-checking-random-replay.t;
  t/1711-vial-execution-model-cardinality-preflight.t;
  t/1712-vial-execution-scoreboard-cardinality-preflight.t;
  t/1713-vial-execution-coverage-cardinality-preflight.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1685-vial-architecture-scale-cap-policy.t
  t/1687-vial-parser-direct-import-cap-order.t
  t/1693-vial-parser-source-byte-cap-order.t
  t/1686-vial-semantic-action-cap-order.t
  t/1688-vial-semantic-parallel-fiber-cap-order.t
  t/1689-vial-semantic-declaration-cap-order.t
  t/1690-vial-semantic-scoreboard-capacity-order.t
  t/1691-vial-semantic-cross-max-bins-order.t
  t/1692-vial-semantic-type-shape-cap-order.t
  t/1694-hial-vial-bridge-configuration-cap-order.t
  t/1695-hial-vial-bridge-endpoint-cap-order.t
  t/1696-hial-vial-bridge-observation-cap-order.t
  t/1697-hial-vial-bridge-probe-cap-order.t
  t/1698-hial-vial-bridge-type-cap-order.t
  t/1699-hial-vial-bridge-transaction-cap-order.t
  t/1700-hial-vial-bridge-event-cap-order.t
  t/1701-hial-vial-bridge-residue-cap-order.t
  t/1702-hial-vial-bridge-backend-binding-cap-order.t
  t/1703-hial-vial-bridge-source-map-cap-order.t
  t/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t
  t/1625-vial-architecture-scale-execution-total-fiber-limit.t
  t/1705-vial-execution-selected-domain-cap-order.t
  t/1706-vial-execution-operation-cardinality-cap-order.t
  t/1707-vial-execution-type-cap-order.t
  t/1708-vial-execution-source-map-cap-order.t
  t/1709-vial-execution-binding-cardinality-preflight.t
  t/1710-vial-execution-random-attempt-authority.t
  t/1634-vial-architecture-scale-checking-random-replay.t
  t/1711-vial-execution-model-cardinality-preflight.t
  t/1712-vial-execution-scoreboard-cardinality-preflight.t
  t/1713-vial-execution-coverage-cardinality-preflight.t
---

Every selected numeric architecture-scale cap remains the hard ceiling of its
declaring component, not a promise that each canonical route can reach it. The
versioned policy keeps workload levels unchanged and records the component
ceiling, the route's actual earliest deciding authority, and a measured route
boundary when one exists. It authorizes earlier same-layer enforcement and
terminal defenses, but no limit increase, decrease, re-levelling, support,
budget, capacity, or accepted-profile change. Decision [[vial-execution-scale-axis-outcomes]]
retains the reachability evidence; decision `0093` is the rationale authority.

Direct import fan-out that cannot fit the remaining 64-source import ceiling
is rejected at the first overflowing direct edge before recursive catalog
source parsing. Malformed imported bytes cannot mask the established import
limit, while accepted depth-first ordering, semantic identities, and the
per-edge nested-import defense remain unchanged.

Per-source and combined imported-source bytes are admitted before lexing each
affected source. Malformed token bytes cannot mask either established byte
limit, while exact-boundary source order and semantic identities remain
unchanged.

Scenario action accounting now reserves the 65,536-expanded-action ceiling
before inspecting the next action node. Repeat bodies are checked once, then
additional copies are admitted with division-before-multiplication arithmetic.
Crossing the cap therefore retains the established scenario-level diagnostic
and cannot be masked by malformed later syntax or leak a partial semantic
report; exact-boundary accepted behavior is unchanged.

Parallel depth and fiber count are admitted before join-value resolution.
Known fiber excess therefore retains its action-level limit diagnostic even
when the join value is invalid; accepted boundary identities are unchanged.

Each declaration family is admitted immediately after its section shape is
parsed. Known excess therefore wins before malformed later package sections,
with unchanged exact-boundary projection and report identities.

Scoreboard capacity and coverage-cross `max_bins` are admitted before
dependent transaction or coverpoint resolution. Known scalar excess therefore
retains its established limit diagnostic and atomic failure even when a later
reference is invalid; admitted declarations retain every reference, type,
domain, key, and Cartesian-product validation.

List length, record field count, and aggregate depth are admitted before
recursive inner-type resolution. Invalid inner types cannot mask any known
outer-shape excess, while exact-boundary semantic identities remain unchanged.

Before dependent validation, normalization, or record materialization, the
bridge admits actor parameters, endpoints, observations, probes, distinct
types, combined transactions/events, retained residue, backend bindings, and
each projected source map. Terminal collection defenses and accepted manifest
bytes remain intact. Exact manifest bytes stay terminal because canonical
encoding alone decides size; boundary acceptance and adjacent excess are frozen.

Compact execution admission covers profile/scenario/operation/fiber counts
before context construction, bindings after bridge indexing but before record
construction, and novel types/source maps before insertion. Random exhaustion
and exact projected plan bytes stop final decision, ExecutionIR, and report
materialization. Saturating arithmetic, terminal defenses, earlier
SemanticIR/bridge authorities, diagnostics, and accepted plan identities remain
unchanged.

Before model normalization, checking admission counts instances and
saturating-adds each referenced definition's scalar cells. Both excesses retain
`/models` and create no model records; accepted terminal counts must equal
preflight, with the scalar terminal check retained. Scoreboard definitions
retain earlier semantic scalar admission; execution then preflights instance
count and aggregate admitted capacity before scoreboard normalization, with
terminal count agreement and the same `/scoreboards` failure surface.
Coverage preflights coverpoints and a saturating bins-plus-cross-tuples total
before normalization, then requires the normalized counts to agree while
retaining terminal caps. Semantic cross `max_bins` and the coverpoint route's
parser byte cap remain earlier authorities; both local excesses retain
`/coverage`. Fault and random groups keep their separate owner and nonclaims.
