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
date: 2026-08-22
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
  perl/FSM/VIAL/Parser.pm; perl/FSM/VIAL/SemanticBuilder.pm;
  scripts/run_vial_semantic_bridge_measurement_matrix.pl;
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
  t/1648-vial-architecture-scale-backend-emission-osvvm.t; t/1650-vial-architecture-scale-backend-emission-family-qualification.t; t/1651-vial-architecture-scale-runtime-stream-construction.t; t/1652-vial-balanced-portable-bridge-admission.t; t/1653-vial-balanced-portable-composition.t; t/1654-vial-balanced-portable-emission.t; t/1655-vial-architecture-scale-runtime-balanced-qualification.t; t/1656-vial-architecture-scale-measurement-foundation.t; t/1657-vial-architecture-scale-semantic-bridge-measurement.t;
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
  prove -Iperl t/1601-vial-architecture-scale-semantic-catalog.t
  t/1602-vial-architecture-scale-bridge-fanout.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1645-vial-architecture-scale-backend-emission-foundation.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t t/1650-vial-architecture-scale-backend-emission-family-qualification.t t/1651-vial-architecture-scale-runtime-stream-construction.t t/1652-vial-balanced-portable-bridge-admission.t t/1653-vial-balanced-portable-composition.t t/1654-vial-balanced-portable-emission.t t/1655-vial-architecture-scale-runtime-balanced-qualification.t t/1656-vial-architecture-scale-measurement-foundation.t t/1657-vial-architecture-scale-semantic-bridge-measurement.t t/1658-vial-architecture-scale-semantic-bridge-measurement-matrix.t
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

Decision `0077` resolves balanced `.17.2.7.2` without widening portable AHB or
revision-1 scale. The private direct-IAL1 `architecture_scale_probe` profile is
`balanced_portable` revision `2`, with exact facts and capability
`hial_vial.bridge_qualification.balanced_portable_v2`. Caller-sealed bridge,
execution, backend-input, and portable-SV entrypoints independently validate
full identities and shapes; public callers, near misses, mutation, and forged
identity fail closed. The real binding equation remains one unit/domain, 126
data endpoints, 32 probes, 16 aliases, 1,744 fields, and 128 events: 2,048
bindings, 109 fields per alias. Completed `.2.3` regenerates source, runs six
fresh gates, rebuilds stages twice plus replay, derives all semantics, and
rejects injected evidence. Completed `.2.4` then negotiates fifteen exact
requirements and emits a byte-equal eight-artifact/three-source graph: 503,279
source bytes and 3,605 maps cover all 1,024 operations and 2,048 bindings.
Public bypass and hostile evidence reject atomically; repository-volume staging
is residue-free. Completed `.17.2.7.3` closes deterministic generation with one
exact fifteen-runtime/one-balanced ownership partition. It constructs each
member only through its family producer, embeds every complete child report and
authority identity, normalizes stage applicability without erasing child
semantics, and independently regenerates the complete aggregate from checked
sources. Nested runtime/balanced staging cleans both repository-volume roots
after success or failure. Public planning/AHB/revision 1/other backends and
provider, compile, runtime, trace, result, support, performance, capacity, and
reached-boundary claims stay unchanged and unclaimed. Focused t/1653-t/1655
re-derive and falsify these boundaries; `.17.2` is complete.

Completed `.17.3.1` provides the common measurement foundation without running
a provider or external verification tool. It closes all twelve decision-0056
stage records, requires correctness-only validation before a guarded measured
ordinal, samples controller and descendant process evidence every 250 ms,
retains explicit unsupported reasons, enforces the smaller stage/backend
timeout, validates disjoint stage artifacts plus the complete owned-tree
census, and removes repository-derived staging after success, exception,
timeout, or rejected output. Accepted measured records publish by same-volume
atomic directory rename; byte-identical retry is unchanged, collision and
injected commit failure are residue-free. The guard wrapper remains the safety
authority and exports only its effective threshold evidence. Workload and
semantic identities exclude volatile measurements. t/1656 re-derives the
record and lifecycle and falsifies forged paths, timeouts, reports, guard
admission, ordinals, stage order, external classification, unreported output,
publication collision, and publication failure. `.17.3.2` now has a caller-
sealed semantic/bridge adapter. It accepts no constructed input or report,
reconstructs each family through its canonical producer, reruns every stage
payload independently, isolates reconstruction in the construct stage, and
delegates guard, sampling, timeout, artifact census, and cleanup authority to
the foundation. Original canonical evaluation JSON
remains a stage artifact; the embedded generic oracle uses a collision-checked
projection that changes family `path` keys to `semantic_path` so semantic
pointers cannot be mistaken for machine-local paths. Independent validation
regenerates both forms. The adapter retains validation plus exactly three gate
or five qualification ordinals only after the family oracle accepts, and
records an authoritative family rejection as validated-but-not-measured. It
executes no provider, compiler, simulator, or external verification tool and
makes no performance-budget, support, capacity, or reached-boundary claim. A
resumable matrix publisher now freezes the exact four-level inventory across
fourteen semantic and thirteen bridge axes. It admits only a clean Git
revision below the real guard; publishes each complete profile set atomically
with every raw record; resumes only byte-valid same-revision evidence; rejects
collisions and ambiguous crash staging; and seals family/full manifests only
after exact child censuses share one Git/host/tool/guard identity. The runner
uses the adapter's exact `gate_measurement`, `qualification_measurement`, and
`validation` mode vocabulary in inventory and reports, avoiding a second
translation contract. The guarded 108-profile capture and independent
regeneration close `.17.3.2` with one accepted immutable matrix.

The first exact capture attempt at the combined-source-byte limit exposed a
real controller timeout that adapter revalidation initially masked as a
successful-output mismatch. The repaired adapter preserves rejected-stage
zero-output evidence and the original controller diagnostic while rederiving
only completed family stages. The unchanged ordinary referenced-declaration
fixture now completes through chunked ASCII lexing with a Unicode-preserving
fallback and linear four-state mask conversion. The fixed timeout and every
support, performance-budget, capacity, and reached-boundary nonclaim remain
unchanged. The obsolete old-revision partial publication was re-censused and
removed. The clean full capture retains 108 reports, two family manifests, one
complete manifest, and 186 raw records with no exclusions. `.17.3.3` now owns
provider-free execution/checking measurement.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
