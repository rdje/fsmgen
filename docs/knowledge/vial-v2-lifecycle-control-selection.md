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
  - "how is VIAL v2 lifecycle control mapped to portable SystemVerilog?"
  - "which check seams advance the portable VIAL lifecycle controller?"
  - "does the VIAL v1 trace validator reject execution IR v2?"
date: 2026-09-30
status: current
tags: [vial, hial, lifecycle, semantic-ir, logical-time, deadlines, target-neutral]
evidence: >-
  docs/vial-spec/lifecycle-control-v2.md;
  docs/vial-spec/portable-systemverilog-lifecycle-v2.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md;
  docs/decisions/0100-portable-systemverilog-lifecycle-uses-a-static-check-seam-controller.md;
  docs/decisions/0034-vial-expressiveness-is-not-bounded-by-synthesizability.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md;
  perl/FSM/Support/VIALSemanticFamilyRegistry.pm;
  perl/FSM/VIAL/LifecycleControl.pm;
  t/1807-vial-v2-lifecycle-selection.t;
  t/1808-vial-v2-lifecycle-compiler-phases.t;
  t/1809-vial-v2-portable-sv-lifecycle-contract.t;
  t/data/vial_v1_contract_frozen_hial_dut.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: >-
  prove -Iperl t/1807-vial-v2-lifecycle-selection.t t/1808-vial-v2-lifecycle-compiler-phases.t t/1809-vial-v2-portable-sv-lifecycle-contract.t &&
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

Decision `0100` selects one finite statically emitted fixture-level controller
beside the unchanged scenario scheduler. It advances only after initialization,
after an inactive-edge barrier, and after scenario terminal publication. One
monotone fixture-wide lifecycle counter prevents later selected scenarios from
resetting deadline time; reachable milestones commit before inclusive expiry
checks. Version-2 backend, source-map, trace, projection, and result-manifest
schemas remain distinct, while the target-neutral lifecycle result retains its
already versioned v1 schema. No v2 backend maturity advances at selection.

The private v1 `FSM::VIAL::Backend::TraceValidator` does not currently validate
the ExecutionIR schema/version/profile envelope before parsing. T1809 therefore
characterizes that a canonical v1-shaped trace is accepted against lifecycle
ExecutionIR v2. Adapter, emitter, runner, result producer, and public v2 `run`
still reject before a false result can be published. Proposed repair child
`.19.2.3.1.2.1` must close this isolation gap before emitter implementation.

T1809 separates current HIAL DUT emission from the fixed-input VIAL byte
contract. Its original complete graph oracle was introduced at
`d200f9fe7268ba292b898c64a3d3e6bd992b4441`. Reconstructing that project-owned
source through its plan/emission interface reproduces the original graph;
substituting only its recovered DUT text into the current plan reproduces the
same graph. The maintained emission-only text fixture is authenticated by its
own digest in T1809. The test also emits the current DUT and compares VIAL
negotiation; no historical DUT is compiled or run.

The initial mixed-dependency oracle became stale after later HIAL repairs:
explicit internal roles affect scalar truthiness emission, and
`69ae18454c52a51079da17edd7c31c423ef66bb5` removes invalid same-value fan-in
assertions. Complete old/current graph comparison isolates the differences to
DUT text and its dependent length/digest references; VIAL plan identity and
the synthetic normalized-result oracle remain unchanged. Holding the DUT
input fixed preserves the original VIAL oracle without reverting those HIAL
repairs. This evidence does not qualify HDL execution or VIAL v2 runtime.
