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
date: 2026-08-10
status: current
tags: [hial, vial, scalability, execution-ir, semantic-ir, task-tree]
evidence: >-
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md;
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
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
  rg -n 'T=6,319|T=29,508|T=22|Durability gap'
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md
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

Completed `.17.2.1`-`.17.2.5` implement source, semantic, bridge, execution,
and checking-state families. Decision `0075` selects checked-AHB anchored
backend routes: portable SV accepts `T=6,319` at 16,776,830 source bytes and
rejects `6,320`; portable VHDL/OSVVM select `T=29,508` and reject `29,509` in
the portable foundation; native UVM accepts only reference `T=21` and must
reject adjacent unsupported `T=22`. Active `.17.2.6` owns VHDL-validator,
OSVVM-provider/map, native-UVM-negotiation, catalog, and generator repairs.
These figures were freshly re-derived and falsified for selection, but the
tracked executable producer/watcher is an explicit durability gap until those
repairs close. No capacity claim is made.

Related: [[vial-execution-scale-reachability]], [[vial-semantic-scale-catalog]],
[[vial-execution-scale-source-cap-representation]],
[[hial-vial-verification-fixture-architecture]].
