---
id: vial-execution-scale-reachability
title: VIAL execution scale uses canonical routes and reports the earliest real cap
answers:
  - "how will VIAL execution graph scale workloads be generated?"
  - "which VIAL execution scale axes reach their selected limits?"
  - "why does VIAL execution scale need a private qualification binder?"
  - "does the public VIAL binder accept the architecture scale bridge capability?"
  - "how are exact 1 MiB 4 MiB and 16 MiB VIAL plans constructed?"
  - "how is the one million random attempt boundary proved?"
  - "which cap wins for VIAL operations bindings types and source maps?"
  - "why must VIAL operation source maps use global indexes across scenarios?"
  - "how do VIAL total-fiber and simultaneously-live-fiber gate workloads stay orthogonal?"
  - "how does the VIAL execution scale gate materialize 512 distinct types?"
  - "how does the VIAL execution gate produce exactly 8192 source maps?"
  - "how does the VIAL execution gate prove exactly 8192 random attempts and replay equality?"
date: 2026-08-10
status: current
tags: [vial, execution-ir, scale, binder, bridge, random, replay, plan, limits]
evidence: >-
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md; docs/decisions/0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md; perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm; perl/FSM/VIAL/ExecutionBuilder.pm; perl/FSM/VIAL/ExecutionRandom.pm; perl/FSM/Support/VIALExecutionContract.pm; t/1552-vial-execution-ir.t; t/1603-vial-architecture-scale-execution-foundation.t; t/1604-vial-architecture-scale-execution-topology.t; t/1605-vial-architecture-scale-execution-fibers.t; t/1606-vial-architecture-scale-execution-types.t; t/1607-vial-architecture-scale-execution-source-maps.t; t/1608-vial-architecture-scale-execution-random-replay.t;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json; vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: prove -Iperl t/1552-vial-execution-ir.t t/1603-vial-architecture-scale-execution-foundation.t t/1604-vial-architecture-scale-execution-topology.t t/1605-vial-architecture-scale-execution-fibers.t t/1606-vial-architecture-scale-execution-types.t t/1607-vial-architecture-scale-execution-source-maps.t t/1608-vial-architecture-scale-execution-random-replay.t && rg -n 'selected_scenarios|expanded_operations_per_scenario|expanded_operations_total|total_fibers|simultaneous_live_fibers|bindings|execution_types|source_map_records|random_attempts|serialized_plan_bytes' perl/FSM/Support/VIALExecutionContract.pm perl/FSM/VIAL/ExecutionBuilder.pm docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md
---

Decision `0061` selects the `execution_graph_v1` reachability contract. The
fixed AHB route owns scenarios, operations, fibers, source maps, random/replay,
and plan bytes. A plain direct-IAL1 actor owns execution types. The scale-only
bridge event family owns the 2,048-binding gate through a caller-sealed private
binder admission. Public `ExecutionBuilder->build`, public planning, backends,
support accounting, and the decision-`0060` nonclaims remain unchanged.

The first `.17.2.4.2` implementation slice now constructs that binding gate
from ordinary IAL1 and VIAL sources. Exactly 2,042 ordinal events plus the six
unit/domain/endpoint/probe/transaction/field records produce 2,048 bindings.
The plan contains one type, scenario, operation, and fiber, 2,047 source-map
records, and 2,656,823 serialized bytes. The private binder admits only the
exact generator caller and exact qualification protocol metadata; the public
binder and altered metadata still return stable closed errors. The private
capability is labelled `qualification_only` and `private_nonportable`.

The second slice uses the exact 1,326-byte checked AHB PPIF and the public
binder for three gate candidates. Scenarios are 32 × one reset; operations in
one scenario are one × 256 resets; total operations are 32 × 32 resets. Their
canonical plans are respectively 59,907, 121,163, and 409,363 bytes with
49, 273, and 1,041 source-map records. All retain 22 bindings, seven types, one
root fiber per scenario, and one simultaneously live fiber. Independent runs
freeze exact semantic/bridge/plan hashes without introducing the private scale
capability.

That scenario gate exposed a pre-existing source-map defect from execution
implementation commit `44dbecd1a`: each scenario-local operation array began
at zero, and its local index was incorrectly emitted as a global plan path.
`ExecutionBuilder` now adds the global operation offset only for source-map
paths. Scenario-local static ranks and operation IDs remain unchanged, while
every `/operation_graph/operations/N` path occurs exactly once. The resulting
plan identity is propagated through byte-locked native-UVM, portable-VHDL, and
OSVVM galleries and exact GHDL/OSVVM qualification reports.

The third slice implements the two gate-level fiber axes without changing the
builder. The 128-total-fiber gate authors five sequential `all` parallels with
31/31/31/31/3 reset-bearing children. It therefore has exactly 128 total and
32 simultaneously live fibers, 132 operations, 149 source maps, and a
79,987-byte plan. The live-width gate authors one depth-two `all` tree with two
outer fibers and 29 nested children. It has exactly 32 total/live fibers, 32
operations, 49 maps, and a 43,811-byte plan. Exact parent/child closure, joins,
successor chains, ranks, phases, semantic/bridge/plan hashes, public checked-AHB
capability, independent reruns, and hostile-input rejection are frozen. The
gate-level group width deliberately holds the non-primary live count to its own
gate value; higher fiber levels and their earlier-cap evidence remain separate
unfinished constructions.

The fourth slice implements the 512-type gate through an ordinary non-annotated
direct-IAL1 actor rather than the fixed AHB route. Public inputs and VIAL
endpoints use every exact unsigned four-state width from 1 through 512. The
unchanged public binder therefore materializes 512 distinct execution shapes,
each with one semantic ID, carrier type ID, and drive relation. The plan has
514 bindings, 514 maps, one reset/root fiber, and 735,488 bytes; its canonical
bridge report is exactly 8,237,394 bytes. It retains only the public direct-
IAL1 source capability and exact IAL1/IAL0 review route. The generated
HIAL/VIAL sources are 17,901/63,780 bytes with frozen identities. Mutation,
caller-source injection, and unfinished levels fail
closed. Optional backend probe-name collection preserves a null absent bridge
annotation instead of autovivifying `{}`, so the actor and scheduler report
remain byte-consistent.

The fifth slice implements the 8,192-source-map gate through the frozen
checked-AHB route and unchanged public binder. Seventeen maps are fixed by the
domain, endpoint/probe relations, six transaction fields, and six events; the
generator adds 8,175 genuine resets to reach the exact total. Every plan path
is unique, operation map `N` resolves semantic action `N` and one ordered byte
span, and the resets form one closed successor chain in one root fiber. The
generated VIAL is 115,478 bytes, the unchanged bridge report is 508,968 bytes,
and the exact plan is 2,949,646 bytes. Semantic, bridge, workload, and plan
identities are frozen; public checked-AHB capability isolation, independent
reruns, mutation rejection, missing-source rejection, and unfinished-level
closure all pass.

The sixth slice implements the 8,192-attempt gate through that same public AHB
route. One referenced two-state u64 choice spans the complete unsigned range;
its equality constraint targets deterministic candidate
`0x7da2c124f3fb4c11` at zero-based attempt 8,191. One check-phase expectation
references the choice. Evaluation runs independent generation twice, then
builds a strict replay through the unchanged binder. Generated and replayed
decision records retain identical occurrence, normalized value, attempt,
distribution, type, operation reference, and source span; only `origin` changes.
The generated/replayed plans are 34,295/34,294 bytes and contain one scenario,
operation, occurrence, and root/live fiber, eight types, 22 bindings, and 19
maps. Exact source/SemanticIR/bridge/workload/generated-plan/replayed-plan
identities, public capability isolation, replay mutation, source mutation,
missing-source rejection, and unfinished-level closure are frozen.

The nominal execution limits are not all reachable. Scenarios and
simultaneously live fibers reach their exact 4,096 and 16,384 limits. Operations
per scenario, total operations, total fibers, and source maps encounter the
16-MiB serialized-plan cap at selected higher levels. Binding and type fanout
encounter earlier VIAL-source or bridge event/type caps. Each excess workload
must report the first diagnostic in the canonical semantic → bridge → plan
order; it may not forge a downstream object to reach a preferred number.

Random attempts are independently reachable: a u64 equality constraint targets
the candidate at zero-based attempt `N - 1`. Attempts 8,192, 262,144, and
1,000,000 succeed exactly; target 1,000,001 returns
`VIAL_RANDOM_EXHAUSTED`. Replay must preserve the keyed normalized value and
attempt exactly.

The AHB plan-byte recipes use real reset operations and referenced semantic
identifiers. They produce canonical plans of exactly 1,048,576, 4,194,304, and
16,777,216 bytes; one additional complete reset operation is rejected. These
are construction/boundary facts only. `.17.2.4.2` remains active for exact plan
bytes, higher random levels, final qualification, and cleanup; no scale
capacity is supported until later measurement and promotion.
