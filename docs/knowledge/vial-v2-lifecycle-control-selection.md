---
id: vial-v2-lifecycle-control-selection
title: VIAL v2 lifecycle control has one target-neutral revision-1 contract
answers:
  - "what is the selected VIAL v2 lifecycle_control syntax?"
  - "how does VIAL express readiness without UVM phases?"
  - "how does VIAL express completion and drain without objections?"
  - "what are VIAL lifecycle dependencies and services?"
  - "what defaults does VIAL lifecycle control use?"
  - "how are VIAL lifecycle deadlines measured?"
  - "what happens when a VIAL lifecycle deadline expires?"
  - "is VIAL lifecycle_control implemented or public?"
  - "which task implements VIAL lifecycle SemanticIR next?"
date: 2026-09-04
status: current
tags: [vial, hial, lifecycle, semantic-ir, logical-time, deadlines, target-neutral]
evidence: >-
  docs/vial-spec/lifecycle-control-v2.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md;
  docs/decisions/0034-vial-expressiveness-is-not-bounded-by-synthesizability.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md;
  perl/FSM/Support/VIALSemanticFamilyRegistry.pm;
  t/1807-vial-v2-lifecycle-selection.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: >-
  prove -Iperl t/1807-vial-v2-lifecycle-selection.t &&
  rg -n 'lifecycle_control|fixture_background|Intrinsic order and defaults|Finite bounds|implementation unavailable' docs/vial-spec/lifecycle-control-v2.md docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md docs/book/src/16dg-vial-public-lifecycle-reference.md perl/FSM/Support/VIALSemanticFamilyRegistry.pm
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

Every lifecycle has one full deadline measured in its HIAL-reviewed logical
domain. A deadline of N cycles starting at C includes check seam C + N - 1.
Failure stops new stimulus, requests cooperative cancellation and service
stop, and attempts finalization under an independent default 256-cycle bound.
A failed lifecycle can never return to pass.

The registry still reports only `selection: selected`. Source, SemanticIR,
binding, execution, plan, emission, compile, runtime, result, parity, and public
maturity are unavailable on every profile. Until `.19.2.2` implements the
family, public parsing rejects a nonempty block with
`VIAL_FAMILY_UNSUPPORTED` and no partial semantic report. No lifecycle
capability is advertised.
