---
id: vial-architecture-scale-proof
title: VIAL architecture scale is proved by orthogonal families with stage-local oracles, not capacity claims
answers:
  - how will VIAL architecture scalability be proved?
  - what are the VIAL scale workload families?
  - are VIAL scale gate and qualification candidates supported capacity?
  - how are VIAL scale performance budgets selected?
  - does VIAL architecture scale prove whole product big and really big designs?
  - which execution graph scale limits are reachable before earlier caps?
  - what exact workloads prove VIAL backend emission scale?
  - where are the VIAL portable backend source byte boundaries?
  - why does native UVM reject the portable backend scale ladder?
  - how are VIAL runtime-stream measurement inputs constructed without tools?
  - how was the balanced portable bridge blocker resolved?
  - what closes deterministic VIAL scale generation before measurement?
  - how does VIAL architecture scale measurement work?
  - how does VIAL measure Linux logical cores without a Perl POSIX constant?
  - where are VIAL scale measurement artifacts staged and published?
  - does the VIAL measurement foundation execute external tools?
  - which VIAL scale families are measured first?
  - what does semantic and bridge scale measurement claim?
  - how does semantic bridge measurement preserve semantic paths without allowing host paths?
  - how is the semantic bridge scale matrix resumed and published?
  - how are legacy semantic bridge and execution checking matrix publications byte bounded?
  - does semantic bridge matrix validation require profile isolation?
  - how does semantic bridge measurement preserve a failed stage diagnostic?
  - how does the exact combined source byte profile stay below its timeout?
  - how are VIAL execution and checking stages measured?
  - why does source-free VIAL scale have no measurement record?
  - how is the execution checking scale matrix resumed without borrowing identity?
  - why did execution checking matrix resume stop before profile twenty?
  - how is execution checking matrix validation memory bounded?
  - why cannot the nineteen pre-repair scale reports enter the repaired revision seal?
  - why does the isolated execution checking matrix still stop at operations total over limit?
  - where must the VIAL total operation cap be enforced?
  - where is the revision e4b95dbd execution checking prefix archived?
  - how is the VIAL serialized plan cap enforced before random decision materialization?
  - how is structural backend emission measured without executing an HDL tool?
  - is OSVVM provider verification an external verification tool run?
  - how is the structural backend emission matrix resumed and published?
  - why does the backend emission matrix isolate every profile in a child?
  - what do the backend emission publication and IPC ceilings mean?
  - how will portable Verilator runtime scale measurement reuse the qualified runner?
  - why did portable Verilator runtime reachability expose a phase-order defect?
  - how does portable SystemVerilog schedule a check-to-react successor?
  - why is portable SystemVerilog direct drive a separate prerequisite?
  - how does portable SystemVerilog implement a direct endpoint drive?
  - why are portable direct drives limited to input carriers and root fibers?
  - what Runner timeout risk was found before portable runtime measurement?
  - why did the portable SystemVerilog scale oracle move to revision 2?
  - why must backend emission measurement use a revision 2 publication namespace?
  - what is the portable SystemVerilog 16 MiB boundary after scheduler repair?
  - how does portable runtime-stream activity reach exactly 10,000 records?
  - why is portable qualification 15,000 records instead of 100,000?
  - where are the authored portable runtime qualification sources and structural oracle?
  - what are the final tracked portable runtime artifact graph sizes?
  - how is balanced portable measurement scoped?
  - which immutable VIAL calibration files need current revalidation or explicit versioning?
  - how is the immutable VIAL calibration publication dispositioned?
  - what must happen before VIAL architecture scale regression budgets are promoted?
date: 2026-09-02
status: current
tags: [hial, vial, scalability, execution-ir, semantic-ir, task-tree]
evidence: >-
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  docs/decisions/0077-vial-balanced-portable-uses-a-caller-sealed-revision-2-qualification-bridge.md;
  docs/decisions/0078-vial-execution-total-operation-cap-precedes-graph-materialization.md;
  docs/decisions/0080-portable-systemverilog-rolls-backward-successors-by-logical-phase.md;
  docs/decisions/0081-portable-systemverilog-direct-drive-uses-root-owned-zero-duration-driver-slots.md;
  docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md;
  docs/decisions/0089-linux-logical-core-discovery-uses-bounded-kernel-authorities.md;
  docs/decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md;
  docs/decisions/0095-calibration-closure-versions-atomically-after-current-validator-drift.md;
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md;
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/VIAL/ArchitectureScaleWorkload.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm; perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm;
  perl/FSM/VIAL/ArchitectureScaleBalancedPortable.pm; perl/FSM/VIAL/ArchitectureScaleBalancedPortableMeasurement.pm; perl/FSM/VIAL/ArchitectureScaleBalancedPortableMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleRuntimeBalancedQualification.pm;
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleCalibrationClosure.pm;
  perl/FSM/VIAL/ArchitectureScaleCalibrationClosurePublication.pm;
  perl/FSM/VIAL/ArchitectureScaleCapConsistency.pm;
  perl/FSM/VIAL/ArchitectureScaleCalibrationDisposition.pm;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm;
  perl/FSM/VIAL/ArchitectureScalePortableRuntimeMaterialization.pm;
  perl/FSM/VIAL/Parser.pm; perl/FSM/VIAL/SemanticBuilder.pm;
  scripts/run_vial_semantic_bridge_measurement_matrix.pl;
  scripts/audit_vial_semantic_bridge_profile_isolation.pl;
  scripts/run_vial_execution_checking_measurement_matrix.pl;
  scripts/run_vial_backend_emission_measurement_matrix.pl;
  perl/FSM/VIAL/ArchitectureScaleSemanticCatalog.pm;
  perl/FSM/VIAL/ArchitectureScaleBridgeFanout.pm;
  perl/FSM/HIAL/VIALBridge/Builder.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm;
  perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/Support/VIALExecutionContract.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/PortableVHDL.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/OSVVM.pm;
  perl/FSM/Support/VIALVHDLEmissionContract.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm;
  t/1626-vial-architecture-scale-execution-total-operation-limit.t;
  t/1644-vial-backend-emission-authority-alignment.t;
  t/1645-vial-architecture-scale-backend-emission-foundation.t;
  t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t;
  t/1601-vial-architecture-scale-semantic-catalog.t;
  t/1602-vial-architecture-scale-bridge-fanout.t;
  t/1648-vial-architecture-scale-backend-emission-osvvm.t; t/1650-vial-architecture-scale-backend-emission-family-qualification.t; t/1651-vial-architecture-scale-runtime-stream-construction.t; t/1652-vial-balanced-portable-bridge-admission.t; t/1653-vial-balanced-portable-composition.t; t/1654-vial-balanced-portable-emission.t; t/1655-vial-architecture-scale-runtime-balanced-qualification.t; t/1656-vial-architecture-scale-measurement-foundation.t; t/1657-vial-architecture-scale-semantic-bridge-measurement.t; t/1659-vial-architecture-scale-execution-checking-measurement.t; t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t; t/1661-vial-architecture-scale-backend-emission-measurement.t;
  t/1557-vial-portable-sv-backend-emission.t;
  t/1558-vial-verilator-run-integration.t;
  t/1770-vial-semantic-bridge-profile-isolation-audit.t;
  t/1771-vial-legacy-matrix-publication-bounds.t;
  t/1662-vial-architecture-scale-backend-emission-measurement-matrix.t;
  t/1663-vial-architecture-scale-portable-runtime-materialization.t;
  t/1683-vial-architecture-scale-calibration-closure.t;
  t/1764-vial-architecture-scale-calibration-disposition.t;
  t/1765-vial-architecture-scale-regression-promotion-policy.t;
  vial/qualification/sv_portable_verilator_runtime_gate.vial;
  vial/qualification/sv_portable_verilator_runtime_qualification.vial;
  docs/knowledge/vial-execution-scale-reachability.md;
  docs/knowledge/vial-semantic-scale-catalog.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16da-vial-balanced-portable-composition.md;
  docs/book/src/16db-vial-structural-backend-emission-matrix.md;
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md
reverify: >-
  rg -n 'semantic_catalog_v1|bridge_fanout_v1|execution_graph_v1|checking_state_v1|backend_emission_v1|runtime_stream_v1|big.*really_big'
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md
  docs/book/src/16d-hial-vial-verification-architecture.md
  docs/book/src/16da-vial-balanced-portable-composition.md &&
  rg -n '524,288|65,536|run_vial_backend_emission_measurement_matrix'
  docs/book/src/16db-vial-structural-backend-emission-matrix.md &&
  rg -n '88%|4,096 MiB|pinned host|earliest authoritative cap|same-volume'
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'T=6,318|T=29,506|T=22|Durability'
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md &&
  rg -n 'balanced_portable_v2|private_nonportable|architecture_scale_probe|binding_count|SUPPORTED_CAPABILITY'
  perl/FSM/HIAL/VIALBridge/Builder.pm perl/FSM/VIAL/ExecutionBuilder.pm
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md &&
  rg -n 'vial_architecture_scale_measurement|SAMPLER_INTERVAL_NS|STAGING_BASE|PUBLICATION_BASE|measured runs require'
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm &&
  rg -n '_linux_logical_cores|_linux_cpu_list_count|_linux_cpuinfo_logical_core_count|kernel_max'
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm t/1656-vial-architecture-scale-measurement-foundation.t &&
  rg -n 'vial_architecture_scale_semantic_bridge_measurement_set|measurement_evidence_projection|semantic_path|canonical family'
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm &&
  rg -n 'utf8::downgrade|pack.*B\*|validation_rejected|prior_stage_failed'
  perl/FSM/VIAL/Parser.pm perl/FSM/VIAL/SemanticBuilder.pm
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm &&
  rg -n 'expected_drift|synthetic-allocation|_load_report_publication'
  scripts/audit_vial_semantic_bridge_profile_isolation.pl
  t/1770-vial-semantic-bridge-profile-isolation-audit.t &&
  rg -n 'source_free_construction|preflight_dominated|_measurement_inputs|bind_plan'
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm perl/FSM/VIAL/ArchitectureScaleCheckingState.pm &&
  rg -n 'profile_publication|capture_identity|source-free|72-profile'
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm
  scripts/run_vial_execution_checking_measurement_matrix.pl
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'provider_verification|authoritative_non_emission|parse_validate|bind_plan|emit'
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurement.pm &&
  rg -n 'owned_shapes|MAX_PUBLICATION_BYTES|MAX_PROFILE_WORKER_RESULT_BYTES|capture_identity|provider_verification_profiles'
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurementMatrix.pm
  scripts/run_vial_backend_emission_measurement_matrix.pl &&
  rg -n 'runtime activity|shared lifecycle|second tool runner|IASIM'
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md &&
  rg -n 'successor phase rollover|_successor_rollover_statements|operation-phase-order|vial_inactive_barrier'
  docs/decisions/0080-portable-systemverilog-rolls-backward-successors-by-logical-phase.md
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm
  t/1557-vial-portable-sv-backend-emission.t
  t/1558-vial-verilator-run-integration.t &&
  rg -n 'input_carrier_direct_drive_only|root_fiber_direct_drive_only|direct_driver_safe_zero_finalization|direct-drive-conflict'
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm perl/FSM/VIAL/Backend/TraceValidator.pm
  perl/FSM/Support/VIALExecutionContract.pm
  docs/decisions/0081-portable-systemverilog-direct-drive-uses-root-owned-zero-duration-driver-slots.md &&
  rg -n '5N \+ 260|10,000|15,000|three quarters|VerilatorLifecycle|content-addressed|workspace-normalized'
  docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md
  docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md &&
  rg -n 'expected_full_graph_bytes|final_tracked_public_run_rederived|record_families|preflight_dominated|caller-sealed'
  perl/FSM/VIAL/ArchitectureScalePortableRuntimeMaterialization.pm
  t/1663-vial-architecture-scale-portable-runtime-materialization.t &&
  rg -n 'reset bus (1948|2948)|timeout \(cycles bus 4096\)|scale_response_zero'
  vial/qualification/sv_portable_verilator_runtime_gate.vial
  vial/qualification/sv_portable_verilator_runtime_qualification.vial &&
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
  t/1602-vial-architecture-scale-bridge-fanout.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1645-vial-architecture-scale-backend-emission-foundation.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t t/1650-vial-architecture-scale-backend-emission-family-qualification.t t/1651-vial-architecture-scale-runtime-stream-construction.t t/1652-vial-balanced-portable-bridge-admission.t t/1653-vial-balanced-portable-composition.t t/1654-vial-balanced-portable-emission.t t/1655-vial-architecture-scale-runtime-balanced-qualification.t t/1656-vial-architecture-scale-measurement-foundation.t t/1657-vial-architecture-scale-semantic-bridge-measurement.t t/1658-vial-architecture-scale-semantic-bridge-measurement-matrix.t t/1659-vial-architecture-scale-execution-checking-measurement.t t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t t/1661-vial-architecture-scale-backend-emission-measurement.t
  t/1662-vial-architecture-scale-backend-emission-measurement-matrix.t
  t/1770-vial-semantic-bridge-profile-isolation-audit.t
  t/1771-vial-legacy-matrix-publication-bounds.t
---

Decisions `0055` and `0056` select architecture-scale proof without claiming capacity.
Six orthogonal families isolate source/SemanticIR, bridge, execution, checking,
backend emission, and runtime streams; one balanced candidate checks interaction.
Axes retain reference, gate, qualification, exact-limit, and excess levels.
Timing/RSS is invalid unless stage-local semantics, identity, source maps,
artifacts, rerun, result, failure, and cleanup all pass. Fixed 88%-host and
4,096-MiB-descendant safety is immediate; budgets require clean pinned-host
calibration, while earliest-cap dominance remains explicit. None of these are
support, whole-product capacity, synthesis, native-UVM-runtime, or parity claims.

Decision `0083` selects portable-SystemVerilog runtime-stream qualification
without promoting support or capacity. Each authored reset adds five records
plus the final expectation, so `records(N)=5N+260`; qualified probes reach
10,000/15,000 records at `N=1,948/2,948`. The 100,000 candidate hits the
67,108,864-byte runtime envelope and 25,000 hits the artifact-graph cap.
Qualification therefore uses the largest 5,000-record step at or below three
quarters of that cap: the 15,000 probe used 47,502,039 bytes and left
19,606,825 hard-cap bytes, whereas 20,000 left 4,194,825. `.17.3.5.2` reruns
ordinary source-to-emission and seals 32,098,531/47,505,049-byte final graphs;
their changed provenance bytes are measured identities, not probe adjustments.

Completed `.17.2.1`-`.17.2.5` cover source through checking state. Decision
`0075` selects checked-AHB backend routes: portable-SV oracle revision 2
accepts `T=6,318` and rejects `6,319`; portable VHDL/OSVVM v2 selects
`29,505/29,506` after trace-v2/result-contract refinements; native UVM emits
only `T=21` and rejects `T=22`. The closed `BackendEmissionAuthority`, repair
parent `.17.2.6.2`, caller-sealed foundation `.17.2.6.3.1`, four profile
ladders, and family closure `.17.2.6.3.6` preserve exact inventories, maps,
checks, content-addressed reruns, atomic rejection, and cleanup. Runtime
`.17.2.7.1` constructs three profiles/five levels without provider/tool
execution or runtime/capacity claims. Exact historical counts remain in the
task evidence and decisions `0075`/`0055`, not duplicated here.

Decision `0077` resolves balanced `.17.2.7.2` through a private caller-sealed
direct-IAL1 revision-2 route while public AHB/revision 1 remains unchanged. Its
`1+1+126+32+16+1,744+128` equation yields 2,048 bindings; canonical composition,
portable-SV emission, and the fifteen-runtime/one-balanced partition reject
hostile evidence and clean staging. Dedicated docs retain exact artifacts/maps;
provider, runtime, support, performance, capacity, and boundary remain unclaimed.

Completed `.17.3.1` supplies twelve closed stages, correctness-first 250-ms
sampling, smaller-of timeouts, disjoint artifact census, same-volume atomic
publication, and exact cleanup under the guard wrapper. t/1656 falsifies
identity, path, timeout, ordinal, stage, output, collision, and failure drift.
Linux logical-core identity comes from bounded canonical kernel authorities
with bounded `/proc/cpuinfo` fallback; missing or hostile inputs fail closed.
Darwin profiling and the evidence schema remain unchanged.
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
A tracked read-only audit compares direct and fresh-child profile validation; both reproduce 102 current matches plus decision 0095's six drifts. Direct validation reaches 2,236,547,072-byte maximum RSS with 2,058,420,224-byte guard headroom; isolation lowers retained parent state, but no failure is reproduced.
Separately, t1771 recenses and reloads every immutable legacy publication: the 111-file semantic/bridge set remains below its 524,288-byte storage ceiling and the 75-file execution/checking set below 1,048,576 bytes.
Exact-cap controls pass; cap-plus-one and hostile topology/JSON controls reject. These are containment and process-lifetime witnesses, never budgets or capacity claims.

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
withholds family/full seals until every child agrees. The completed repair
chain gives each raw identity an advisory lock and safe orphan recovery,
isolates each profile lifecycle below the real guard, enforces the unchanged
total-operation and serialized-plan caps before known-excess materialization,
and reuses one private sealed random transcript after independent validation.
Revision-keyed interruption archives preserve every incompatible prefix;
signal, timeout, malformed child output, identity drift, collision, and
residue remain rejected. Decisions `0078`/`0079`, the owning task, and Git
retain the exact causal chronology and boundary counts. The shared plan
projection and decision-`0079` transcript preserve canonical byte equality and
all terminal defenses while rejecting known excess before final list, map, IR,
or report allocation. Exact adapters retain attempts, identities, boundary
outcomes, the fixed 300-second ceiling, and clean staging.

Revision `9c0209c22` seals the 40-execution/32-checking matrix: 75 files/
7,312,415 bytes at identity `execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0`,
41 accepted/19 rejected, 31 applicable/five inapplicable/two preflight-dominated
measurements, 62/ten controller applicable/inapplicable, 119 raw records, ten
source-free profiles, and zero exclusions. Same-identity resume after the 88%
host cutoff left zero staging; guarded `--validate` reloads with no diagnostics.
This is not capacity, support, budget, public-API, or backend/tool execution.

`.17.3.4.1` measures only structural `backend_emission_v1` production through
caller-sealed `construct`, `parse_validate`, `bridge`, `bind_plan`, and `emit`
payloads. The adapter reconstructs repository anchors, validates the complete
canonical evaluation before retention, records three/five samples only for
emitted gate/qualification routes, and keeps reference, limit, excess, native-
UVM rejection, and preflight-dominated outcomes correctness-only. OSVVM's
sealed repository-local provider verification is read-only and included in
`emit`; it is explicitly not an external verification-tool run. Exact t/1661
proves mutation, applicability/provider contradiction, defensive return,
failure cleanup, independent regeneration, and zero staging under the real
guard. No compile/run/trace/result, support, budget, capacity, reached-boundary,
native-UVM-runtime, parity, or public-API claim follows.

Completed `.17.3.4.2` adds the immutable matrix publisher over that adapter. Its
twenty ordered profiles come only from producer `owned_shapes`; reference,
limit, and excess use validation while gate/qualification use sampling only
when the canonical outcome emitted artifacts. Every capture, resume, and
reload runs in a separate guard-visible child, publishes the complete report
first, and returns only a closed compact entry. Publication and IPC envelopes
are independently bounded; content collisions, noncanonical/oversized child
results, signals, identity drift, reordered profiles, provider borrowing, and
ambiguous crash staging reject. Family/complete manifests require one clean
revision/host/tool/guard identity and retain exact dominance, samples,
exclusions, provider classification, content identity, and nonclaims. These
bounds and manifests are structural evidence, not IASIM/tool execution,
support, performance budgets, capacity, or reached-boundary claims.

Clean `fdc6e6a1b` seals twenty profiles as 22 files/2,232,452 bytes at
`backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735`:
13 emitted/seven non-emission, twelve validation/eight measurement candidates,
six applicable/two inapplicable, 24 raw/zero excluded, five read-only provider,
and three preflight-dominated. The largest is 442,009 bytes below its 524,288
ceiling; family/complete manifests are 30,203/2,535 bytes. Exact t1662 and a
fresh guarded reload agree; 12,656 seconds is provenance, not a budget/capacity.

Completed `.17.3.5.1.1` repairs the portable-SV phase-order defect found by a
real gate-reachability probe. It preserves immutable operation/static-rank
order and tracks the last phase consumed by each closed lowering. Same/forward
successors call directly; check-to-react uses one genuine inactive-edge
barrier, while react/check-to-drive increments the logical cycle once. Start no
longer advances unconditionally, and negotiation rejects phase-order or
kind/eligible-phase drift before artifacts. Structural tests cover every
backward pair, same-phase retention, blocking reset, and fail-closed drift; the
qualified-Verilator Runner produces a genuine passing inserted expectation and
byte-identical repeated result/artifact graphs. Decision `0080` retains the
rationale, alternatives, rollback, and three verification legs.

Completed `.17.3.5.1.2` repairs the separately proven direct-drive defect.
Ordinary VIAL now retains the exact `update_driver` endpoint target and drive
relation; the portable backend renegotiates effect/binding/relation/value/port
identity, assigns the normalized value, and emits one exact drive-phase record
without consuming a barrier. Same-fiber writes stay ordered, a later
react/check crosses one genuine sample barrier, conflicting live sibling writes
reject deterministically, and scenario finalization restores each used slot to
safe zero with dedicated provenance. Trace validation independently rejects
forged endpoint, value, transaction-field, or logical-slot claims. The portable
profile fails closed for inout and non-root direct drive and publishes both as
explicit nonclaims. Decision `0081` retains the rule and three proof legs.

The signoff audit also found that portable `parallel` rendering is a property
scheduler rather than a general child-fiber interpreter. The preserved
ordinary-source RED replaces a child `await` with `reset`: target-neutral
planning succeeds, the former backend emitted complete artifacts, and the
reset was never invoked. Completed `.17.3.5.1.3` now reconstructs parallel
ownership and admits only distinct direct child fibers containing exactly one
terminal `await`; every other recognized kind, multi-operation sequence,
nested parallel, or malformed ownership fails before artifacts. Decision
`0082` records the compatibility boundary and the machine support contract
publishes `general_parallel_child_sequences` as a nonclaim.
The caller-sealed balanced revision-2 route remains separately governed by
decision `0077`: it qualifies structural emission only, claims no runtime
execution of its reset-child fibers, and retains its exact private shape gate
and public-bypass rejection.

Portable-SV oracle v2 accepts `T=6,318` at 16,774,723 bytes/6,351 maps and
rejects `6,319` before 16 MiB; runtime selection remains separate. `0601fa8aa`
preserves matrix v1 historically and gives v2 a non-colliding namespace.
Clean `4487f0fe3` t1662 reloads 22 v2 files/2,252,381 bytes at identity
`backend-emission-matrix/9d634e6a898cc58a3566e6f52c846c19ea1b06c509961338a57c3322840c4fe1`.
Exact t1683 seals seven authorities/nine families/216 profiles/356 raw records,
zero exclusions, and 92 candidate/124 noncandidate profiles at identity
`calibration-closure/92ef0a203e18ce8de8b17cf819f36b73fe0889f00fdcb4def8b2b0e9eeb9dcc5`;
its 232 referenced artifacts total 28,398,586 bytes.

`.17.3.8.1` measures the sole balanced structural gate; clean `118b3bfb68902c9479ca4c83a714b23ebb50501a` seals `.2`
as three immutable files/1,280,699 bytes and complete identity `balanced-portable-matrix/d0619d4cce4d8eebb6b486d70bc41368d9d5f379ce54f87c6843f931ca462900`.
Exact t1682 plus fresh reload retain one validation, three raw/zero excluded and four cleaned/zero-residue records; execution
remains inapplicable. `.17.3.9.1` seals independent statistics/candidate-budget derivation; `.2` owns atomic publication;
`.17.4`/`.17.5` retain cap enforcement/promotion. No runtime, capacity, support, parity, or API claim follows.

Clean `b66de5ce6` t1684 and reload seal two files/1,376,483 bytes at identity
`calibration-closure-publication/1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8`.
The 256-file/32,007,521-byte store is 232 selected artifacts, 22 backend-v1
files, and two closure files.

`ArchitectureScaleCalibrationDisposition` requires the independent 23-group/
161-dimension cap proof, authenticates that exact store, and revalidates all
108 semantic/bridge profiles. Decision 0095 versions the complete selected
lineage historical after six bridge mismatches; a separate census binds VHDL-
derived backend/runtime drift to the 127-byte `460df366e` and 112-byte
`0b6e83979` repairs. The decision and executable authority retain the exact
counts, hashes, identities, drift records, union, and falsifiers without
duplicating them here. Recapture is required for current-performance use, not
cap closeout; candidate budgets, support, and capacity remain unpromoted.

Decision 0096 selects an independently versioned eleven-profile current corpus:
one semantic, bridge, execution, checking, and balanced route plus all three
backend-emission and runtime routes. Historical comparison contracts 356 raw
records to 33, but no old timing becomes a budget. Current v2 capture requires
eleven validations plus 33 fresh records, zero exclusions, exact provider-
resolved applicability, and atomic same-volume publication. Missing providers
are unavailable rather than passing; unmatched-host timing is informational.
Capture, budgets, regression/CI, public truth, and closeout remain separate,
and whole-product capacity stays outside the claim.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]], [[vial-architecture-scale-regression-promotion-capture]].
