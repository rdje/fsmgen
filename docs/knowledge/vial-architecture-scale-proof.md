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
date: 2026-08-21
status: current
tags: [hial, vial, scalability, execution-ir, semantic-ir, task-tree]
evidence: >-
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/VIAL/ArchitectureScaleWorkload.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/PortableVHDL.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/OSVVM.pm;
  perl/FSM/Support/VIALVHDLEmissionContract.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm;
  t/1644-vial-backend-emission-authority-alignment.t;
  t/1645-vial-architecture-scale-backend-emission-foundation.t;
  t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t;
  t/1648-vial-architecture-scale-backend-emission-osvvm.t; t/1650-vial-architecture-scale-backend-emission-family-qualification.t;
  docs/knowledge/vial-execution-scale-reachability.md;
  docs/knowledge/vial-semantic-scale-catalog.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  rg -n 'semantic_catalog_v1|bridge_fanout_v1|execution_graph_v1|checking_state_v1|backend_emission_v1|runtime_stream_v1|big.*really_big'
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n '88%|4,096 MiB|pinned host|earliest authoritative cap|same-volume'
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'T=6,319|T=29,508|T=22|Durability'
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md &&
  prove -Iperl t/1644-vial-backend-emission-authority-alignment.t
  t/1645-vial-architecture-scale-backend-emission-foundation.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t t/1650-vial-architecture-scale-backend-emission-family-qualification.t
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

Completed `.17.2.1`-`.17.2.5` cover source through checking-state families.
Decision `0075` selects checked-AHB backend routes: portable SV accepts
`T=6,319` and rejects `6,320`; portable VHDL/OSVVM select `29,508/29,509`;
native UVM owns reference `T=21` and must reject unsupported `T=22`.
Completed repair parent `.17.2.6.2` supplies linear VHDL validation, sealed
OSVVM provider reuse, 66-entry wrapper map closure, and exact native-UVM
selected-shape negotiation. One closed `BackendEmissionAuthority` source now
feeds the workload catalog and VHDL/native-UVM discovery. It separates OSVVM's
six-source portable foundation from one fixed adapter and provider, names the
portable-only 16-MiB authority, and records native UVM's one-million-map cap
beside its exact 21-operation/75-map/14-check/25-mapping selection. Unknown,
missing, obsolete, or contradictory fields fail closed; the guarded repair
family passes 18 files/7,248 tests. Completed caller-sealed foundation
`.17.2.6.3.1` retains its private profile-neutral qualification mode. Completed
portable-SystemVerilog ladder `.2` now owns exactly T=21/1,024/4,096/6,319
acceptance and T=6,320 rejection. It rebuilds ordinary canonical routes twice,
freezes the ordered eight-artifact/three-source identities and
54/1,057/4,129/6,352 complete maps, validates exact operation-ID and manifest
closure, and rejects the first 16-MiB excess with no partial graph. Reports
remain defensive and content-addressed; success, expected rejection, and
consumer failure leave no repository-local scale-stage residue. Completed
portable-VHDL ladder `.3` owns exactly T=21/128/512/29,508 acceptance and
T=29,509 rejection. Its caller-sealed child emits the ordinary Parser/
PlanBuilder routes twice, freezes all seventeen artifact paths and six source
identities, validates 59/166/550/29,546 complete maps and all twenty static
checks, and proves atomic rejection with no partial graph. The selected ladder
observes a stable 37-byte generated-identifier maximum below the separate
255-byte limit. Completed OSVVM ladder `.4` owns the same five T levels through
one callback-scoped provider verification and two defensive emissions. Its
accepted levels freeze sixteen artifacts, the fixed adapter plus six
byte-identical portable sources at 120,911/179,280/391,248/16,781,090 total
source bytes, 66/173/557/29,553 complete adapter-first translated maps, seven
advanced mappings, six semantic guards, twelve wrapper checks, and twenty
portable prerequisite checks. The adjacent level returns only the wrapper's
portable-foundation diagnostic with no partial provider or artifact evidence.
Completed native-UVM generator leaf `.17.2.6.3.5` owns five public route outcomes but emits only the selected T=21 review
graph: sixteen artifacts, ten SystemVerilog sources/138,345 bytes, 75 structural maps with six intentional operation
associations, fourteen passing checks, 25 selected mappings, seven review stages, and five review-closure checks. Its four
non-reference levels all execute the adjacent T=22 negotiation rejection; the three levels beyond the gate are explicitly
preflight-dominated/not-constructed. Independent T=128 and changed-same-count T=21 witnesses reject before artifacts. Family
closure `.17.2.6.3.6` freezes 13/7 outcomes; runtime child `.17.2.7.1` alone is active without runtime/support/capacity claims.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
