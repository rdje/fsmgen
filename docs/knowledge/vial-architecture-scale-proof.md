---
id: vial-architecture-scale-proof
title: VIAL architecture scale is proved by orthogonal families with stage-local oracles, not capacity claims
answers:
  - "how will VIAL architecture scalability be proved?"
  - "what are the VIAL scale workload families?"
  - "are VIAL scale gate and qualification candidates supported capacity?"
  - "how are VIAL scale performance budgets selected?"
  - "does VIAL architecture scale prove whole product big and really big designs?"
  - "which execution graph scale limits are reachable before earlier caps?"
  - "what exact workloads prove VIAL backend emission scale?"
  - "where are the VIAL portable backend source byte boundaries?"
  - "why does native UVM reject the portable backend scale ladder?"
  - "how are VIAL runtime-stream measurement inputs constructed without tools?"
  - "how was the balanced portable bridge blocker resolved?"
  - "what closes deterministic VIAL scale generation before measurement?"
  - "how does VIAL architecture scale measurement work?"
  - "where are VIAL scale measurement artifacts staged and published?"
  - "does the VIAL measurement foundation execute external tools?"
  - "which VIAL scale families are measured first?"
  - "what does semantic and bridge scale measurement claim?"
  - "how does semantic bridge measurement preserve semantic paths without allowing host paths?"
  - "how is the semantic bridge scale matrix resumed and published?"
  - "how does semantic bridge measurement preserve a failed stage diagnostic?"
  - "how does the exact combined source byte profile stay below its timeout?"
  - "how are VIAL execution and checking stages measured?"
  - "why does source-free VIAL scale have no measurement record?"
  - "how is the execution checking scale matrix resumed without borrowing identity?"
  - "why did execution checking matrix resume stop before profile twenty?"
  - "how is execution checking matrix validation memory bounded?"
  - "why cannot the nineteen pre-repair scale reports enter the repaired revision seal?"
  - "why does the isolated execution checking matrix still stop at operations total over limit?"
  - "where must the VIAL total operation cap be enforced?"
  - "where is the revision e4b95dbd execution checking prefix archived?"
  - "how is the VIAL serialized plan cap enforced before random decision materialization?"
date: 2026-08-23
status: current
tags: [hial, vial, scalability, execution-ir, semantic-ir, task-tree]
evidence: >-
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  docs/decisions/0077-vial-balanced-portable-uses-a-caller-sealed-revision-2-qualification-bridge.md;
  docs/decisions/0078-vial-execution-total-operation-cap-precedes-graph-materialization.md;
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/VIAL/ArchitectureScaleWorkload.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm; perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm;
  perl/FSM/VIAL/ArchitectureScaleBalancedPortable.pm;
  perl/FSM/VIAL/ArchitectureScaleRuntimeBalancedQualification.pm;
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm;
  perl/FSM/VIAL/Parser.pm; perl/FSM/VIAL/SemanticBuilder.pm;
  scripts/run_vial_semantic_bridge_measurement_matrix.pl;
  scripts/run_vial_execution_checking_measurement_matrix.pl;
  perl/FSM/VIAL/ArchitectureScaleSemanticCatalog.pm;
  perl/FSM/VIAL/ArchitectureScaleBridgeFanout.pm;
  perl/FSM/HIAL/VIALBridge/Builder.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/PortableVHDL.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/OSVVM.pm;
  perl/FSM/Support/VIALVHDLEmissionContract.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm;
  t/1626-vial-architecture-scale-execution-total-operation-limit.t;
  t/1644-vial-backend-emission-authority-alignment.t;
  t/1645-vial-architecture-scale-backend-emission-foundation.t;
  t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t;
  t/1601-vial-architecture-scale-semantic-catalog.t;
  t/1602-vial-architecture-scale-bridge-fanout.t;
  t/1648-vial-architecture-scale-backend-emission-osvvm.t; t/1650-vial-architecture-scale-backend-emission-family-qualification.t; t/1651-vial-architecture-scale-runtime-stream-construction.t; t/1652-vial-balanced-portable-bridge-admission.t; t/1653-vial-balanced-portable-composition.t; t/1654-vial-balanced-portable-emission.t; t/1655-vial-architecture-scale-runtime-balanced-qualification.t; t/1656-vial-architecture-scale-measurement-foundation.t; t/1657-vial-architecture-scale-semantic-bridge-measurement.t; t/1659-vial-architecture-scale-execution-checking-measurement.t; t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t;
  docs/knowledge/vial-execution-scale-reachability.md;
  docs/knowledge/vial-semantic-scale-catalog.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16da-vial-balanced-portable-composition.md
reverify: >-
  rg -n 'semantic_catalog_v1|bridge_fanout_v1|execution_graph_v1|checking_state_v1|backend_emission_v1|runtime_stream_v1|big.*really_big'
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md
  docs/book/src/16d-hial-vial-verification-architecture.md
  docs/book/src/16da-vial-balanced-portable-composition.md &&
  rg -n '88%|4,096 MiB|pinned host|earliest authoritative cap|same-volume'
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'T=6,319|T=29,508|T=22|Durability'
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md &&
  rg -n 'balanced_portable_v2|private_nonportable|architecture_scale_probe|binding_count|SUPPORTED_CAPABILITY'
  perl/FSM/HIAL/VIALBridge/Builder.pm perl/FSM/VIAL/ExecutionBuilder.pm
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md &&
  rg -n 'vial_architecture_scale_measurement|SAMPLER_INTERVAL_NS|STAGING_BASE|PUBLICATION_BASE|measured runs require'
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm &&
  rg -n 'vial_architecture_scale_semantic_bridge_measurement_set|measurement_evidence_projection|semantic_path|canonical family'
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm &&
  rg -n 'utf8::downgrade|pack.*B\*|validation_rejected|prior_stage_failed'
  perl/FSM/VIAL/Parser.pm perl/FSM/VIAL/SemanticBuilder.pm
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm &&
  rg -n 'source_free_construction|preflight_dominated|_measurement_inputs|bind_plan'
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm perl/FSM/VIAL/ArchitectureScaleCheckingState.pm &&
  rg -n 'profile_publication|capture_identity|source-free|72-profile'
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm
  scripts/run_vial_execution_checking_measurement_matrix.pl
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
  t/1602-vial-architecture-scale-bridge-fanout.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1645-vial-architecture-scale-backend-emission-foundation.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t t/1650-vial-architecture-scale-backend-emission-family-qualification.t t/1651-vial-architecture-scale-runtime-stream-construction.t t/1652-vial-balanced-portable-bridge-admission.t t/1653-vial-balanced-portable-composition.t t/1654-vial-balanced-portable-emission.t t/1655-vial-architecture-scale-runtime-balanced-qualification.t t/1656-vial-architecture-scale-measurement-foundation.t t/1657-vial-architecture-scale-semantic-bridge-measurement.t t/1658-vial-architecture-scale-semantic-bridge-measurement-matrix.t t/1659-vial-architecture-scale-execution-checking-measurement.t t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t
---

Decisions `0055` and `0056` select architecture-scale proof without claiming capacity.
Six orthogonal families isolate source/SemanticIR, bridge fanout, execution
graphs, checking state, backend emission, and runtime streams; one conservative
balanced candidate checks interaction. Each axis has reference, gate-candidate,
qualification-candidate, exact-limit, and over-limit levels. Every timing/RSS
sample is invalid unless its stage-local semantic, identity, source-map,
artifact, deterministic-rerun, result, failure, and cleanup oracles pass.
Fixed 88%-host/4,096-MiB-descendant safety applies immediately; performance
budgets derive immutably from clean pinned-host calibration and do not fail on
unmatched hosts. Earliest-cap dominance is reported honestly. These candidates
are not support, multi-unit/domain, mixed-language, native-UVM-runtime, full-
language, whole-product `big`/`really_big`, synthesis, or general-parity claims.

Completed `.17.2.1`-`.17.2.5` cover source through checking state. Decision
`0075` selects checked-AHB backend routes: portable SV accepts `T=6,319` and
rejects `6,320`; portable VHDL/OSVVM select `29,508/29,509`; native UVM emits
only `T=21` and rejects `T=22`. The closed `BackendEmissionAuthority`, repair
parent `.17.2.6.2`, caller-sealed foundation `.17.2.6.3.1`, four profile
ladders, and family closure `.17.2.6.3.6` preserve exact inventories, maps,
checks, content-addressed reruns, atomic rejection, and cleanup. Runtime
`.17.2.7.1` constructs three profiles/five levels without provider/tool
execution or runtime/capacity claims. Exact historical counts remain in the
task evidence and decisions `0075`/`0055`, not duplicated here.

Decision `0077` resolves balanced `.17.2.7.2` with a private caller-sealed
direct-IAL1 revision-2 route, leaving public AHB/revision 1 unchanged. Its real
1+1+126+32+16+1,744+128 equation yields 2,048 bindings; canonical composition,
portable-SV emission, and the fifteen-runtime/one-balanced partition reject
hostile evidence and clean repository staging. The dedicated card/book retains
exact artifacts/maps. Provider/runtime/support/performance/capacity/boundary
claims remain unclaimed; `.17.2` is complete.

Completed `.17.3.1` supplies twelve closed stage records, correctness-before-
measurement, 250-ms controller/descendant sampling, smaller-of timeouts,
disjoint artifact census, same-volume atomic publication, and exact cleanup;
the guard wrapper remains enforcement authority. t/1656 falsifies identity,
path, timeout, ordinal, stage, output, collision, and failure substitutions.
`.17.3.2` adds caller-sealed semantic/bridge reconstruction, independent stage
reruns, and a collision-checked `path` to `semantic_path` evidence projection
while retaining original evaluation JSON as an artifact. Accepted gate and
qualification profiles keep three/five raw ordinals; authoritative rejection
is correctness-only. Its clean guarded publisher resumes immutable reports and
seals exact child censuses at one Git/host/tool/guard identity. The 108-profile
matrix retains 186 raw records and zero exclusions. A first combined-byte run
exposed masked timeout evidence and parser/value-normalization hot paths; the
repair preserves rejected-stage diagnostics, Unicode semantics, the fixture,
and the fixed timeout. Tasks, decisions, and Git retain the detailed evidence.

`.17.3.3` reconstructs only the execution or
checking producer and measures independently rerun `construct`,
`parse_validate`, `bridge`, and `bind_plan` payloads through the common guard,
sampler, artifact census, and cleanup controller. Accepted authorities retain
one validation plus three gate/five qualification records. Authoritative
rejections retain correctness without timing. Preflight-dominated shapes plan
only construct and bind/plan. An envelope-unconstructible source-free outcome
has no workload identity, so it retains regenerated family evidence
without inventing controller records, samples, inputs, or artifacts. Exact
t/1659 rederives and falsifies these boundaries under the real guard. No
provider/tool/backend/runtime, budget, support, capacity, or reached-boundary
claim follows. Its exact publisher freezes the producer-owned ten-execution/
eight-checking axes at four levels (72 profiles) and admits no caller inventory
or reports. Complete controller-backed reports establish one clean revision,
host, tool, and guard capture identity. A closed immutable envelope binds that
provenance to each nested report, including source-free reports that retain no
workload or controller identity of their own. Retry independently regenerates
the report under the real guard, accepts only the same immutable capture, and
withholds family/full seals until every child agrees. A real host-guard stop
before the first publication exposed raw-sample staging. `.17.3.3.1` now gives
each exact stage identity a repository-volume advisory lock, rejects live
contention, and reclaims only recursively validated regular same-volume
orphans; unsafe entries remain untouched. The real interrupted gate/03 tree
was recovered through that protocol with three accepted samples and no
exclusions or residue. The resumed capture seals nineteen profiles, then the
real 4,096-MiB guard stops both the original coordinator and a fresh resume
before profile twenty: `_capture_family` reloads and fully validates every
large stored report in one long-lived process, and Perl retains the high-water
heap across iterations. `.17.3.3.2` now puts every complete profile capture,
resume, and publication-validation lifecycle in one guard-visible child. Full
adapter regeneration and atomic publication/reload remain inside the child;
only a canonical closed compact result can cross its close-on-exec pipe under a
1,048,576-byte ceiling. Signal, exit, exception, malformed/noncanonical/
oversized output, identity drift, and artifact drift fail closed. The nineteen
older reports all bind revision `c7493e3d`: the repaired code can independently
revalidate them, but revision truth forbids relabelling or mixing them into a
later implementation revision's seal. They remain revision-keyed interruption
evidence. A clean isolated capture at `b9463c6` then publishes nineteen fresh
profiles before the profile-twenty worker itself reaches 4,869.5 MiB at
`operations_total/over_limit_v1` and the unchanged 4,096-MiB guard terminates
it. The per-profile lifecycle therefore fixes coordinator retention but
falsifies it as the remaining cause. `ExecutionBuilder::_build_operations`
formerly checked `expanded_operations_total` only after materializing every
selected operation and source map; historical exact t/1626 accordingly needed
a 6,144-MiB opt-in guard. Decision `0078` is implemented by
`_preflight_expanded_operations_total`: immediately after selection it walks
compact repeat/parallel trees with bounded arithmetic, requires equality with
each validated semantic action count, and enforces the same aggregate cap
before bridge indexing. Compact tests accept 1,000,000 and reject 1,000,001
with the unchanged diagnostic; the real exact excess passes in one second
under the unchanged 4,096-MiB guard and proves bridge indexing is never
entered. The terminal check remains. The failed prefix is preserved as
nineteen reports/1,739,213 bytes under its revision-keyed archive. A fresh
revision-14c619367 capture then proves the former profile-twenty excess seals
under the unchanged guard and advances through 22 atomic reports. Profile 23,
`random_attempts/limit_v1`, completes canonical admission but its bind-plan
worker reaches the fixed 300-second effective timeout. The retained report
names `VIAL_SCALE_MEASUREMENT_TIMEOUT` at
`/stage_measurements/bind_plan/timeout`, signal 15, successful preceding
stages, zero failed-stage output, and exact cleanup. The guard does not
terminate it; the failed profile is absent and family/full seals remain
withheld. Source tracing proves redundant evaluation nesting: the stage worker
already runs each payload twice, while each bind-plan payload called the
twice-evaluated canonical helper again. The repair retains double canonical
admission and double stage-payload execution but gives each payload one closed
validated producer evaluation. The random generator precomputes only immutable
SHA-256 prefix/counter bytes and skips rejection/modulo only for an exact full-
space range. Fixed narrow, signed, rejection, wide, gate, qualification,
million-attempt, replay, and exhaustion identities remain exact. The direct
guarded adapter now accepts bind-plan with no diagnostic and exact cleanup.
The clean revision-`e4b95dbd` restart seals all 40 execution profiles and the
execution-family manifest, including exact 16,384/16,385 live-fiber boundary
evidence. It then seals 17 checking profiles before
`random_occurrences/qualification_candidate_v1`. Canonical evaluation returns
the expected `VIAL_EXECUTION_LIMIT_ERROR` at `/plan`, but the measured bind-plan
stage originally timed out at 300 seconds because `ExecutionBuilder`
materialized 32,768 random decisions and source maps, ExecutionIR,
ExecutionReport, and complete canonical plan bytes before enforcing the
16,777,216-byte cap. `.17.3.3.2.3` now streams generated or replay-validated
decision, scenario-ID, and source-map element bytes into a saturating exact
projection over a caller-sealed shared-report base plan. The existing plan cap
runs before a known-excess decision list, source-map suffix, ExecutionIR, or
terminal report is allocated. Accepted plans must match terminal canonical
bytes exactly and still pass the terminal limit. Exact guarded evidence retains
8,440 acceptance at 16,775,415 bytes; the historical `/plan` rejection at
8,441 and 32,768; and 65,536/65,537 dominance order. The former adapter blocker
now exits `expected_rejection` / `validated_not_measured` with no diagnostic,
performance sample, or staging residue. Axis-specific thresholds,
guard/timeout/cap changes, evidence relabelling, and promoted
support/performance/capacity claims remain excluded. The 57 atomic profiles
plus execution-family seal are preserved under the exact revision-`e4b95dbd`
same-volume history archive. Independent post-move reconstruction proves 57
reports/5,662,418 bytes, one 46,735-byte family manifest, profile digest
`e8ba27e0986646a284505966828f3c4fdd0a78a55c24978b7a15bff82625f0f9`,
and all-payload digest
`c9147898a109f21eda6bc8ec370f2b15620518cdb1fb3d7171bf83d9fec49170`;
the active execution/checking namespace and raw staging are empty. Checking-
family and complete seals remain withheld.

Revision `037e56f09` seals 22 profiles before `random_attempts/limit_v1` fails;
its 22 reports/2,609,009 bytes reconstruct at digest `6dbfa2d02f7eee0332881074628d50d2b454fe94ac241137a11d7c651c162d90`.
Decision `0079` is implemented by a private SHA-256-sealed, u32-framed canonical UTF-8 transcript bounded to 16,777,216 + 4 x 65,536 = 17,039,360 bytes. Projection
searches or replay-validates once; accepted materialization independently checks
and consumes records, while known excess allocates no final list/map/IR/report.
Exact adapters preserve identities, attempts, 8,440/8,441/32,768 outcomes, the 300-second stage ceiling, and clean staging; the fresh 72-profile matrix remains under `.17.3.3.2.3.1`.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
