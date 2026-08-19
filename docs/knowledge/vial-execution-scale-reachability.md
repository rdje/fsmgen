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
  - "how does the VIAL execution qualification prove exactly 262144 random attempts and replay equality?"
  - "how does the VIAL execution gate produce an exact one MiB semantic plan?"
  - "how does the VIAL execution qualification produce an exact four MiB semantic plan?"
  - "how does the VIAL execution limit produce an exact sixteen MiB semantic plan?"
  - "how does VIAL reject the first complete execution plan operation above sixteen MiB?"
  - "how does the VIAL execution qualification concentrate 8192 operations in one scenario?"
  - "which cap rejects 65536 and 65537 VIAL operations in one scenario?"
  - "which cap rejects 65536 total VIAL operations across 32 scenarios?"
  - "does the VIAL total-operation axis have a qualified operating point?"
  - "do the VIAL fiber axes reach their qualification levels?"
  - "how does the VIAL fiber oracle check a level it was not written for?"
  - "which VIAL execution axis actually reaches its own nominal cap?"
  - "how is the exact 16384 simultaneously-live-fiber limit proved?"
  - "what rejects 16385 simultaneously live fibers?"
date: 2026-08-19
status: current
tags: [vial, execution-ir, scale, binder, bridge, random, replay, plan, limits]
evidence: >-
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md;
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/VIAL/ExecutionRandom.pm; perl/FSM/Support/VIALExecutionContract.pm;
  t/1552-vial-execution-ir.t; t/1603-vial-architecture-scale-execution-foundation.t;
  t/1604-vial-architecture-scale-execution-topology.t;
  t/1605-vial-architecture-scale-execution-fibers.t;
  t/1606-vial-architecture-scale-execution-types.t;
  t/1607-vial-architecture-scale-execution-source-maps.t;
  t/1608-vial-architecture-scale-execution-random-replay.t;
  t/1613-vial-architecture-scale-execution-random-qualification.t;
  t/1614-vial-architecture-scale-execution-random-limit.t; t/1615-vial-architecture-scale-execution-random-over-limit.t;
  t/1616-vial-architecture-scale-execution-scenario-qualification.t; t/1617-vial-architecture-scale-execution-scenario-limit.t; t/1618-vial-architecture-scale-execution-scenario-over-limit.t;
  t/1619-vial-architecture-scale-execution-operation-qualification.t;
  t/1620-vial-architecture-scale-execution-operation-limit.t; t/1621-vial-architecture-scale-execution-operation-over-limit.t;
  t/1622-vial-architecture-scale-execution-total-operation-qualification.t;
  t/1623-vial-architecture-scale-execution-fiber-qualification.t;
  t/1624-vial-architecture-scale-execution-live-fiber-limit.t;
  t/1609-vial-architecture-scale-execution-plan-bytes.t;
  t/1610-vial-architecture-scale-execution-plan-qualification.t;
  t/1611-vial-architecture-scale-execution-plan-limit.t;
  t/1612-vial-architecture-scale-execution-plan-over-limit.t;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json; vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1552-vial-execution-ir.t
  t/1603-vial-architecture-scale-execution-foundation.t
  t/1604-vial-architecture-scale-execution-topology.t
  t/1605-vial-architecture-scale-execution-fibers.t
  t/1606-vial-architecture-scale-execution-types.t
  t/1607-vial-architecture-scale-execution-source-maps.t
  t/1608-vial-architecture-scale-execution-random-replay.t
  t/1613-vial-architecture-scale-execution-random-qualification.t
  t/1614-vial-architecture-scale-execution-random-limit.t t/1615-vial-architecture-scale-execution-random-over-limit.t
  t/1616-vial-architecture-scale-execution-scenario-qualification.t t/1617-vial-architecture-scale-execution-scenario-limit.t t/1618-vial-architecture-scale-execution-scenario-over-limit.t
  t/1619-vial-architecture-scale-execution-operation-qualification.t
  t/1620-vial-architecture-scale-execution-operation-limit.t t/1621-vial-architecture-scale-execution-operation-over-limit.t
  t/1609-vial-architecture-scale-execution-plan-bytes.t
  t/1610-vial-architecture-scale-execution-plan-qualification.t
  t/1611-vial-architecture-scale-execution-plan-limit.t
  t/1612-vial-architecture-scale-execution-plan-over-limit.t &&
  rg -n 'selected_scenarios|expanded_operations_per_scenario|expanded_operations_total|total_fibers|simultaneous_live_fibers|bindings|execution_types|source_map_records|random_attempts|serialized_plan_bytes'
  perl/FSM/Support/VIALExecutionContract.pm perl/FSM/VIAL/ExecutionBuilder.pm
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md
---

Decision `0061` selects the `execution_graph_v1` reachability contract. The
fixed AHB route owns scenarios, operations, fibers, source maps, random/replay,
and plan bytes. A plain direct-IAL1 actor owns execution types. The scale-only
bridge event family owns the 2,048-binding gate through a caller-sealed private
binder admission. Public `ExecutionBuilder->build`, public planning, backends,
support accounting, and the decision-`0060` nonclaims remain unchanged.

The binding gate is built from ordinary IAL1 and VIAL sources: 2,042 ordinal events plus the six unit/domain/endpoint/probe/
transaction/field records produce 2,048 bindings, one type/scenario/operation/
fiber, 2,047 maps, and 2,656,823 serialized bytes. The private binder admits
only the exact generator caller and exact qualification protocol metadata and
labels the capability `qualification_only`/`private_nonportable`; the public
binder and altered metadata return stable closed errors.

The exact 1,326-byte checked AHB PPIF and public binder drive three gate
candidates: 32 scenarios × one reset, one scenario × 256
resets, and 32 × 32 resets, whose canonical plans are 59,907, 121,163, and
409,363 bytes with 49, 273, and 1,041 maps. All retain 22 bindings, seven
types, one root fiber per scenario, and one simultaneously live fiber.

That gate exposed a pre-existing source-map defect from execution commit
`44dbecd1a`: each scenario-local operation array began at zero and emitted its
local index as a global plan path. `ExecutionBuilder` now adds the global
operation offset only for source-map paths, leaving scenario-local ranks and
operation IDs unchanged, so every `/operation_graph/operations/N` path occurs
exactly once. The corrected plan identity is propagated through byte-locked
native-UVM, portable-VHDL, and OSVVM galleries and exact GHDL/OSVVM reports.

Both gate-level fiber axes are implemented. The 128-total-fiber gate
authors five sequential `all` parallels with 31/31/31/31/3 reset-bearing
children, giving 128 total and 32 live fibers, 132 operations, 149 maps, and a
79,987-byte plan. The live-width gate authors one depth-two `all` tree with two
outer and 29 nested children, giving 32 total/live fibers, 32 operations, 49
maps, and a 43,811-byte plan. Parent/child closure, joins, successor chains,
ranks, and phases are frozen; gate-level group width deliberately holds the
non-primary live count to its own gate value.

The 512-type gate uses an ordinary non-annotated direct-IAL1 actor. Public inputs and VIAL endpoints use every exact unsigned
four-state width from 1 through 512, so the unchanged binder materializes 512
distinct shapes, each with one semantic ID, carrier type ID, and drive
relation. Its 17,901-/63,780-byte HIAL/VIAL sources yield 514 bindings, 514
maps, one reset/root fiber, a 735,488-byte plan, and an exactly 8,237,394-byte
bridge report, retaining only the public direct-IAL1 capability and exact
IAL1/IAL0 review route. Optional backend probe-name collection now preserves a
null absent bridge annotation instead of autovivifying `{}`, keeping actor and
scheduler reports byte-consistent.

The 8,192-map gate: the domain, endpoint/probe
relations, six transaction fields, and six events fix 17 maps, and 8,175
genuine resets complete the total. Every plan path is unique, operation map `N`
resolves semantic action `N` and one ordered byte span, and the resets form one
closed successor chain in one root fiber. Its VIAL source is 115,478 bytes, its
unchanged bridge report 508,968 bytes, and its plan exactly 2,949,646 bytes.

The 8,192-attempt gate uses one referenced two-state
u64 choice spanning the complete unsigned range, an equality constraint on
deterministic candidate `0x7da2c124f3fb4c11` at zero-based attempt 8,191, and
one check-phase expectation. Generated and replayed decisions share occurrence,
normalized value, attempt, distribution, type, operation reference, and span,
differing only in `origin`; their 34,295-/34,294-byte plans hold one scenario,
operation, occurrence, and root/live fiber, eight types, 22 bindings, and 19
maps.

Every gate and ladder freezes exact source/SemanticIR/bridge/workload/plan
identities, topology, spans, and hostile edges, and proves public checked-AHB
capability isolation, independent reruns, replay and source mutation rejection,
missing-source rejection, and unfinished-level closure. None of this
construction evidence adds a public API, support, performance, or capacity
claim.

The plan ladder uses genuine reset actions and referenced HREADYOUT coverage,
never opaque padding. Its 2,974-action gate is exactly 1,048,576 bytes with
2,991 unique maps and ID
`plan/ee10e4a5749a4398b9e62d5a1624d24c74e585459afd57f8cb7503306545c035`;
the 12,166-action qualification is exactly 4,194,304 bytes with 12,183 maps and
ID
`plan/63673374ece891a4234613c00c920ffe60cb4d6d73904ba0be2a2d5799f60d62`
and SHA-256 `bc5d44cd8bdafcb50654c1a7c8c3e0ac7101b496b16084cad9535d901253d076`;
and the 48,850-action limit is exactly 16,777,216 bytes with 48,867 maps and ID
`plan/0709d0c4d1432a218a0f26d9cce0c2b308d2f6fcf95f008bf6ceb65b15dc1e64`
and SHA-256 `0fcf9649c03cf53745842ed4161d42ced9030df297a30a894b56e9ba3448b98e`.
One additional complete reset parses normally but returns only
`VIAL_EXECUTION_LIMIT_ERROR` / `serialized_plan_bytes exceeds the limit
16777216` at `/plan`, with no partial ExecutionIR or plan.

The random ladder closes on the isolated full-range u64 equality route. Candidate `0x00f233516a996304` accepts at attempt 262,143;
its 34,297/34,296-byte generated/replayed plan IDs are
`plan/1f01b357206cb9b768172be41b415084b0ee49ef5494131dd50df74d195d185e` and
`plan/a6d4516c28989dccf67d0989d7a71d8e60cc6315451761947386d86a75123ba7`.
Candidate `0xdd7997a868500a54` accepts at attempt 999,999 with IDs
`plan/02b9207cd9392ba8b0d9e52afe9912f026fc00412ace076ff0fc30a32868b614` and
`plan/90660802ee2bbbebdad84f79f66e1f5b6102befdb45de2f4c36f9a0d7f359f90`.
Replay changes only origin; the graph remains one occurrence/scenario/
operation/root-live fiber, eight types, 22 bindings, and 19 maps. Candidate
`0xce7d67adbe54da82` at attempt 1,000,000 returns exact
`VIAL_RANDOM_EXHAUSTED` from the unchanged public binder with no partial IR or
plan.

The scenario ladder accepts 512 scenarios into a 496,709-byte plan and
4,096 scenarios into a 3,779,103-byte plan; both contain one real reset and
root fiber per scenario, one live fiber, and respectively 529/4,113 maps. The
adjacent 4,097 source parses normally, then the unchanged public binder returns
only `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `selected_scenarios
exceeds the limit 4096`, at `/scenario_ids`, with no partial IR or plan.

The operation-depth qualification accepts 8,192 resets inside one
`scenario_00000000` from a 115,716-byte generated source. The unchanged public
binder keeps the scenario, root-fiber, and simultaneously live counts at one
while total operations reach 8,192, producing 8,209 maps and a 2,955,783-byte
plan below the 16-MiB cap. Every operation is a `drive`-phase reset whose
unique global `/operation_graph/operations/N` path resolves to its own
`/packages/0/fixtures/0/scenarios/0/actions/N` authored action, and the
workload makes no random decision.

Its two higher levels are the first selected pair whose own nominal cap never
wins. The 918,533-byte 65,536-operation source parses into one complete
scenario, then the public binder returns only `serialized_plan_bytes exceeds
the limit 16777216` at `/plan`; one further 14-byte ` (reset bus 1)` record is
rejected first by the parser with `scenario exceeds 65536 expanded actions` at
`/packages/0/fixtures/0/scenarios/0`. Neither leaves a partial ExecutionIR or
plan, the semantic rejection precedes any bridge construction, and each
evaluation reports `expected_rejection` plus one
`VIAL_SCALE_LIMIT_INTERACTION` discrepancy routed to `.17.4`.

The total-operation axis spreads the same work over a fixed fanout of 32
scenarios, and it is the first axis whose *qualification* level is unreachable.
Its 920,547-byte 65,536-operation source clears every stage before the plan:
no scenario approaches the 65,536 expanded-action semantic cap, the parser
returns 32 scenarios of exactly 2,048 expanded actions each, and the
checked-AHB bridge identity is unchanged. Only the serialized plan crosses a
limit, so the binder returns one `serialized_plan_bytes exceeds the limit
16777216` at `/plan`. The evaluation reports `expected_rejection` and one
`VIAL_SCALE_LIMIT_INTERACTION` at `/requested_counts/operations_total` routed
to `.17.4`. The consequence is about the axis, not one level: the
total-operation axis has **no nominal operating point above its 1,024-operation
gate**, and its `limit_v1` and `over_limit_v1` levels stay unowned.

Both fiber axes reach their qualification levels and stay orthogonal there.
`simultaneously_live_fibers` at 1,024 keeps every fiber live at the same
instant, so total and live counts coincide at 1,024 over a 432,528-byte plan.
`fibers_total` at 8,192 runs 265 sequential `all` groups of at most 31 children,
so it reaches 8,192 fibers while its live width stays at the gate value of 32,
over a 3,222,659-byte plan. Both stay well below the 16-MiB cap and report
`accepted` with no discrepancy.

Those levels are checked exactly, not loosely: the fiber oracle recomputes the
bounded parallel-tree recipe from the same helper the renderer used
(`_total_fiber_group_sizes`, `_live_fiber_nested_counts`) and requires the plan
to match it — group sizes, reset and operation counts, maximum live width, root
successor chain, and parent/child closure. The oracle previously restated the
gate's literals, so it rejected any level it had not been written for; deriving
the expectation is what makes a new level as strictly checked as the gate.

The live-width axis reaches its own cap, and it is the first on this leaf that
does. `simultaneously_live_fibers` `limit_v1` is **accepted** at exactly 16,384
total fibers, 16,384 simultaneously live, 16,384 expanded operations, and 16,401
source maps over a 6,553,464-byte plan — well inside the 16-MiB bound, so
nothing pre-empts the `simultaneous_live_fibers` cap of 16,384 that
`FSM::Support::VIALExecutionContract` declares and
`FSM::VIAL::ExecutionBuilder` enforces. The boundary is one fiber wide: the
over-limit source adds exactly one 45-byte nested fiber record (738,151 ->
738,196 bytes), the parser still accepts all 16,385 expanded actions and the
checked-AHB bridge is still built, and only the execution stage rejects with one
`VIAL_EXECUTION_LIMIT_ERROR`, `simultaneous_live_fibers exceeds the limit 16384`,
at `/operation_graph/maximum_simultaneous_live_fibers`, leaving no partial IR or
plan. Because no earlier owner intervenes, that evaluation records **no**
`VIAL_SCALE_LIMIT_INTERACTION`; the reported cap needs no caveat.

The nominal execution limits are not all reachable. Scenarios and
simultaneously live fibers reach their exact 4,096 and 16,384 limits, and both
of those are now proved rather than predicted. Operations
per scenario, total operations, total fibers, and source maps encounter the
16-MiB serialized-plan cap at selected higher levels. Binding and type fanout
encounter earlier VIAL-source or bridge event/type caps. Each excess workload
must report the first diagnostic in the canonical semantic → bridge → plan
order; it may not forge a downstream object to reach a preferred number.

`.17.2.4.2` remains active for the remaining structural levels, final
qualification, and cleanup; these are construction/boundary facts only, and no
scale capacity is supported until later measurement and promotion.
