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
  - "how is structural backend emission measured without executing an HDL tool?"
  - "is OSVVM provider verification an external verification tool run?"
  - "how is the structural backend emission matrix resumed and published?"
  - "why does the backend emission matrix isolate every profile in a child?"
  - "what do the backend emission publication and IPC ceilings mean?"
  - "how will portable Verilator runtime scale measurement reuse the qualified runner?"
  - "why did portable Verilator runtime reachability expose a phase-order defect?"
  - "how does portable SystemVerilog schedule a check-to-react successor?"
  - "why is portable SystemVerilog direct drive a separate prerequisite?"
  - "how does portable SystemVerilog implement a direct endpoint drive?"
  - "why are portable direct drives limited to input carriers and root fibers?"
  - "what Runner timeout risk was found before portable runtime measurement?"
  - "why did the portable SystemVerilog scale oracle move to revision 2?"
  - "what is the portable SystemVerilog 16 MiB boundary after scheduler repair?"
date: 2026-08-24
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
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/VIAL/ArchitectureScaleWorkload.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm; perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm;
  perl/FSM/VIAL/ArchitectureScaleBalancedPortable.pm;
  perl/FSM/VIAL/ArchitectureScaleRuntimeBalancedQualification.pm;
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmissionMeasurementMatrix.pm;
  perl/FSM/VIAL/Parser.pm; perl/FSM/VIAL/SemanticBuilder.pm;
  scripts/run_vial_semantic_bridge_measurement_matrix.pl;
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
  t/1662-vial-architecture-scale-backend-emission-measurement-matrix.t;
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
  rg -n 'T=6,318|T=29,508|T=22|Durability'
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
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
  t/1602-vial-architecture-scale-bridge-fanout.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1645-vial-architecture-scale-backend-emission-foundation.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t t/1650-vial-architecture-scale-backend-emission-family-qualification.t t/1651-vial-architecture-scale-runtime-stream-construction.t t/1652-vial-balanced-portable-bridge-admission.t t/1653-vial-balanced-portable-composition.t t/1654-vial-balanced-portable-emission.t t/1655-vial-architecture-scale-runtime-balanced-qualification.t t/1656-vial-architecture-scale-measurement-foundation.t t/1657-vial-architecture-scale-semantic-bridge-measurement.t t/1658-vial-architecture-scale-semantic-bridge-measurement-matrix.t t/1659-vial-architecture-scale-execution-checking-measurement.t t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t t/1661-vial-architecture-scale-backend-emission-measurement.t
  t/1662-vial-architecture-scale-backend-emission-measurement-matrix.t
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
`0075` selects checked-AHB backend routes: portable-SV oracle revision 2
accepts `T=6,318` and rejects `6,319`; portable VHDL/OSVVM select
`29,508/29,509`; native UVM emits
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

Revision `9c0209c22` seals the complete 40-execution/32-checking matrix: 75 active files/7,312,415 bytes, both family manifests, accepted identity `execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0`, 41 accepted, 19 expected rejection, five inapplicable measurement, two preflight dominated, 31 applicable measurement, 62 controller applicable, ten controller inapplicable, 119 raw records, ten source-free profiles, and zero exclusions.
The 88% host cutoff safely interrupted immutable execution-family revalidation; same-identity resume left zero raw staging and completed checking plus the aggregate seal. A separate guarded `--validate` reloads the same identity and partition with zero diagnostics. This does not claim capacity, reached boundaries, public budgets, backend/tool execution, compile/run/trace/result behavior, support, or a public API.

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

Clean revision `fdc6e6a1b` seals all twenty profiles as 22 immutable files/
2,232,452 bytes at complete identity
`backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735`.
The accepted partition is 13 emitted/seven authoritative non-emission,
twelve validation/eight measurement-candidate, six applicable/two
inapplicable measurement, 24 raw/zero excluded records, five read-only
provider-verification profiles, and three preflight-dominated profiles. The
largest profile is 442,009 bytes below the 524,288-byte publication ceiling;
family and complete manifests are 30,203/2,535 bytes. Exact t/1662 passes in
12,656 seconds under the unchanged guard, and a fresh-process guarded
`--validate` returns the same identity and partition. The elapsed observation
is capture provenance, not a public budget or capacity claim.

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

The compatibility sweep independently reproduced a pre-existing portable
backend-emission oracle drift at clean predecessor `87684237a`. Completed
`.17.3.5.1.4` regenerates every level twice and selects a versioned resolution:
reference/gate/qualification total 164,507/2,803,857/10,910,865 source bytes;
`T=6,318` emits 16,774,723 bytes and 6,351 maps; pre-cap `T=6,319` renders
16,777,362 bytes and rejects atomically under the unchanged 16-MiB cap. The
portable artifact discriminator and schema are revision 2, while shared level
role labels remain stable for the other profiles. Different 414/532-byte
deltas falsify fixed padding. Conditional rollover is already topology-scoped,
and the expanded route needs it, so neither semantic rollback nor cosmetic
146-byte shaving is admitted. The exact source identities, byte-equal reruns,
mutation rejection, family and balanced-prerequisite watchers provide the
rederive/falsify/durability closure without support, performance, or capacity
claims.
Repeated guarded full integration attempts timed out different baseline/direct
executions at Runner's fixed 30-second run wall while byte-identical executions
passed in other attempts under concurrent compiler load. The diagnostic cannot
yet separate process-launch delay from generated-main time. Existing
`.17.3.5.3` owns that stage/timeout evidence and lifecycle policy, so the
observation is neither hidden nor misreported as a direct-drive semantic
failure.

The provider-free runtime construction still does not prove that its selected
semantic activity can be represented truthfully by the shipped trace and
result contracts, and the public Runner still owns the external stages as one
atomic transaction. Selection must bind activity into canonical evidence and
make measurement reuse one private staged lifecycle; source-text patching,
padded or truncated output, duplicated execution semantics, hidden public
widening, and borrowed support or capacity claims are rejected.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
