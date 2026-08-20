---
id: vial-execution-scale-reachability
title: VIAL execution scale gates use canonical caller-sealed routes
answers:
  - "how will VIAL execution graph scale workloads be generated?"
  - "why does VIAL execution scale need a private qualification binder?"
  - "does the public VIAL binder accept the architecture scale bridge capability?"
  - "why must VIAL operation source maps use global indexes across scenarios?"
  - "how do VIAL total-fiber and simultaneously-live-fiber gate workloads stay orthogonal?"
  - "how does the VIAL execution scale gate materialize 512 distinct types?"
  - "how does the VIAL execution gate produce exactly 8192 source maps?"
  - "how does the VIAL execution gate prove exactly 8192 random attempts and replay equality?"
  - "how does the VIAL execution gate produce an exact one MiB semantic plan?"
  - "how does the VIAL fiber oracle check a level it was not written for?"
  - "why does the VIAL direct-IAL1 route parse its source before building its bridge?"
date: 2026-08-20
status: current
tags: [vial, execution-ir, scale, binder, bridge, gates, routing]
evidence: >-
  docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md;
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm;
  t/1603-vial-architecture-scale-execution-foundation.t;
  t/1604-vial-architecture-scale-execution-topology.t;
  t/1605-vial-architecture-scale-execution-fibers.t; t/1606-vial-architecture-scale-execution-types.t;
  t/1607-vial-architecture-scale-execution-source-maps.t;
  t/1608-vial-architecture-scale-execution-random-replay.t;
  t/1609-vial-architecture-scale-execution-plan-bytes.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1603-vial-architecture-scale-execution-foundation.t
  t/1604-vial-architecture-scale-execution-topology.t
  t/1605-vial-architecture-scale-execution-fibers.t t/1606-vial-architecture-scale-execution-types.t
  t/1607-vial-architecture-scale-execution-source-maps.t
  t/1608-vial-architecture-scale-execution-random-replay.t
  t/1609-vial-architecture-scale-execution-plan-bytes.t
---

Decision `0061` assigns each `execution_graph_v1` gate to a shipped canonical
route. Checked-AHB VIAL owns scenarios, operations, fibers, source maps,
random/replay, and plan bytes. A plain direct-IAL1 actor owns execution types.
The scale-only bridge event family owns the binding gate through a private,
caller-sealed `qualification_only` / `private_nonportable` binder admission.
The public binder rejects that scale capability and remains unchanged.

| Gate axis | Exact gate | Canonical result |
|---|---:|---|
| bindings | 2,048 | 2,042 ordinal events plus six fixed records; 2,656,823-byte plan |
| topology | 32 scenarios; 256 operations/scenario; 1,024 operations total | 59,907 / 121,163 / 409,363-byte plans |
| fibers | 128 total; 32 live | orthogonal sequential-group and depth-two recipes |
| execution types | 512 | widths 1–512; 735,488-byte plan |
| source maps | 8,192 | 8,175 real resets plus 17 fixed maps; 2,949,646-byte plan |
| random attempts | 8,192 | candidate accepted at zero-based attempt 8,191; replay differs only in origin |
| serialized plan | 1,048,576 bytes | 2,974 real reset actions and 2,991 unique maps |

Operation source-map paths use a global operation offset across scenarios;
scenario-local ranks and operation IDs remain local. Fiber expectations are
derived from the same bounded recipes as rendering, so every owned level is
checked for exact group widths, topology, successor closure, counts, and spans
rather than against gate-only literals.

Every gate freezes source, workload, SemanticIR, bridge, and plan identities
where those stages exist, plus mutation, missing-source, rerun, replay, caller-
seal, and unfinished-level negatives. Current implementation status is owned by
`docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`; user-facing
behavior is owned by `docs/book/src/16d-hial-vial-verification-architecture.md`.
No gate result is a public support, performance, or capacity claim.

Exact pre-partition prose is recoverable with
`git show 5514e692c:docs/knowledge/vial-execution-scale-reachability.md`.
