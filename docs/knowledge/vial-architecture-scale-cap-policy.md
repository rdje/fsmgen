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

The bridge admits actor-parameter cardinality against the 4,096-configuration
ceiling before type creation or arbitrary-width value normalization. A malformed
overflowing parameter therefore cannot mask the established collection limit;
the terminal whole-manifest defense and accepted manifest bytes remain intact.
Endpoint cardinality is likewise admitted from the clock, reset, and interface
collections before any individual endpoint width is validated or its type and
normalized endpoint record are constructed.
Observation cardinality is admitted before individual monitor roles or their
endpoint references are validated and normalized.

The guarded exact semantic-catalog matrix now closes every selected
qualification, boundary, excess, and declared cap interaction through the
canonical oracle. This completes parser/SemanticIR hardening only; bridge and
later layers retain their separate task owners and nonclaims.
