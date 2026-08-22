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
date: 2026-08-23
status: current
tags: [hial, vial, scalability, execution-ir, semantic-ir, task-tree]
evidence: >-
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  docs/decisions/0077-vial-balanced-portable-uses-a-caller-sealed-revision-2-qualification-bridge.md;
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
before the first publication exposed raw-sample staging that still needs an
exclusive orphan-recovery protocol; `.17.3.3.1` owns that repair before the
exact clean-revision guarded capture resumes.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
