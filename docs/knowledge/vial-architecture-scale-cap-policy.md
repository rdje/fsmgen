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
  perl/FSM/VIAL/SemanticBuilder.pm;
  t/1686-vial-semantic-action-cap-order.t;
  t/1688-vial-semantic-parallel-fiber-cap-order.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1685-vial-architecture-scale-cap-policy.t
  t/1687-vial-parser-direct-import-cap-order.t
  t/1686-vial-semantic-action-cap-order.t
  t/1688-vial-semantic-parallel-fiber-cap-order.t
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

Scenario action accounting now reserves the 65,536-expanded-action ceiling
before inspecting the next action node. Repeat bodies are checked once, then
additional copies are admitted with division-before-multiplication arithmetic.
Crossing the cap therefore retains the established scenario-level diagnostic
and cannot be masked by malformed later syntax or leak a partial semantic
report; exact-boundary accepted behavior is unchanged.

Parallel depth and fiber count are admitted before join-value resolution.
Known fiber excess therefore retains its action-level limit diagnostic even
when the join value is invalid; accepted boundary identities are unchanged.
