---
id: vial-v2-lifecycle-control-selection
title: VIAL v2 lifecycle control compiles through target-neutral planning
answers:
  - "what is the selected VIAL v2 lifecycle_control syntax?"
  - "how does VIAL express readiness without UVM phases?"
  - "how does VIAL express completion and drain without objections?"
  - "what are VIAL lifecycle dependencies and services?"
  - "what defaults does VIAL lifecycle control use?"
  - "how are VIAL lifecycle deadlines measured?"
  - "what happens when a VIAL lifecycle deadline expires?"
  - "is VIAL lifecycle_control implemented or public?"
  - "which VIAL lifecycle compiler phases are implemented?"
  - "how are VIAL lifecycle readiness service conditions represented?"
  - "why must lifecycle condition reference_id remain scalar?"
date: 2026-09-04
status: current
tags: [vial, hial, lifecycle, semantic-ir, logical-time, deadlines, target-neutral]
evidence: >-
  docs/vial-spec/lifecycle-control-v2.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md;
  docs/decisions/0034-vial-expressiveness-is-not-bounded-by-synthesizability.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md;
  perl/FSM/Support/VIALSemanticFamilyRegistry.pm;
  perl/FSM/VIAL/LifecycleControl.pm;
  t/1807-vial-v2-lifecycle-selection.t;
  t/1808-vial-v2-lifecycle-compiler-phases.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: >-
  prove -Iperl t/1807-vial-v2-lifecycle-selection.t t/1808-vial-v2-lifecycle-compiler-phases.t &&
  rg -n 'lifecycle_control|fixture_background|Intrinsic order and defaults|Finite bounds|public_lifecycle_planning' docs/vial-spec/lifecycle-control-v2.md docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md docs/book/src/16dg-vial-public-lifecycle-reference.md perl/FSM/Support/VIALSemanticFamilyRegistry.pm perl/FSM/VIAL/Tool.pm
---

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1` selects revision 1 of
VIAL v2 `lifecycle_control`. One `(lifecycle ...)` source form owns a local
fixture and coordination domain, then declares dependency, readiness,
background-service, stimulus-start, completion, drain, shutdown, finalize,
deadline, and failure records. Normal source wraps the family in `intents`;
terse source retains the identical family form directly in package order.

The lifecycle expands into typed common semantic-family nodes rather than a
target program. Its mandatory order is readiness, stimulus start, completion,
drain, shutdown, service stop, and finalization. Optional requirements only add
AND conditions and cannot weaken the chain. The selected background service is
the target-neutral `fixture_background` aggregate; it is not a generated class
or process.

Every normalized condition has exactly `kind`, scalar-or-null `reference_id`,
scalar-or-null `domain_id`, and an operand array. Intrinsic readiness keeps
dependency prerequisites and `service_ready` prerequisites as distinct ordered
operands. The compiler validates this shape recursively before admitting each
lifecycle semantic node, and T1808 proves that exact condition survives
SemanticIR, ExecutionIR, and plan projection without reinterpretation.

Every lifecycle has one full deadline measured in its HIAL-reviewed logical
domain. A deadline of N cycles starting at C includes check seam C + N - 1.
Failure stops new stimulus, requests cooperative cancellation and service
stop, and attempts finalization under an independent default 256-cycle bound.
A failed lifecycle can never return to pass.

`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2` implements the closed
grammar, typed SemanticIR expansion, HIAL-backed fixture/domain binding,
execution operations, target-neutral plan records, cumulative source maps,
and closed normalized-result validation against the exact plan identity,
record, deadline, and provenance set. Public `check`, `format`, and `plan`
accept the family, while discovery advertises
`vial.family.lifecycle_control.v1` and its deadline capability. All backend
emission, compile, runtime, produced-result, parity, and support maturity stays
unavailable; public version-2 `run` still rejects before allocation.
