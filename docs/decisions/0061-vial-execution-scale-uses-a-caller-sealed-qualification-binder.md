# 0061 — VIAL execution scale uses a caller-sealed qualification binder

- Date: 2026-08-10
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.1`
- Refines: [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0060](0060-vial-bridge-scale-uses-a-qualification-only-direct-ial1-profile.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`
- Ceiling authority: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.1-KNOWLEDGE-CARD`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1107 -> 1108`

## Context

Decision `0060` deliberately made
`hial_vial.bridge_qualification.architecture_scale_v1` private bridge evidence,
not an execution capability. The public `ExecutionBuilder->build` capability
ledger therefore rejects that manifest. History confirms the two boundaries
were introduced independently: `44dbecd1a` shipped the execution allow-list,
while `97dda148d` later shipped the bridge-scale capability. Broadening the
public allow-list would make an exact scale-only IAL1 annotation reachable
through public planning and contradict `0060`.

The fixed AHB bridge is sufficient for scenario, operation, fiber, source-map,
random, replay, and plan-byte axes. A plain direct-IAL1 actor reaches the
512-type gate, but an endpoint-only 2,048-binding attempt reaches the bridge's
16-MiB serialized-manifest cap before execution. The bridge-scale transaction
can represent the binding gate compactly through its closed event family, so a
private execution qualification admission is required for that axis only.

Real canonical probes establish the important boundaries. The AHB route accepts
4,096 scenarios in a 4,374,966-byte plan, 8,192 operations in one scenario in
a 2,833,004-byte plan, 8,192 total fibers in a 3,028,464-byte plan, and 16,384
simultaneously live fibers in a 6,290,456-byte plan. It rejects 16,385 live
fibers at the exact execution limit. A plain direct-IAL1 route accepts 512
execution types; its bridge report is 8,237,394 bytes. Deterministic rejection
sampling accepts exactly 1,000,000 attempts and exhausts at 1,000,001.

## Decision

1. Keep public `ExecutionBuilder->build`, public VIAL planning, the execution
   support contract, and every backend negotiation path unchanged. The private
   architecture-scale bridge capability remains unknown to those surfaces.
2. Add one caller-sealed binder entrypoint used only by
   `FSM::VIAL::ArchitectureScaleExecutionGraph`. It must require that exact
   caller and the exact `architecture_scale_probe` protocol/profile/revision/
   role/fact contract selected by `0060`. It may admit only
   `hial_vial.bridge_qualification.architecture_scale_v1`, classify it as
   qualification-only/non-portable evidence, and produce no backend or support
   claim. Direct calls, altered manifests, and use through the public builder
   must fail closed.
3. Use the frozen AHB IAL2-via-generated-IAL1 bridge for topology, operation,
   source-map, random/replay, and serialized-plan axes. Use an ordinary
   non-annotated direct-IAL1 actor for execution types. Use the caller-sealed
   scale bridge only for bindings, with one bound endpoint, probe, transaction,
   field, and `bindings - 6` ordinal events.
4. Evaluate in the declared stage order: ordinary VIAL source and SemanticIR,
   canonical HIAL bridge, then execution plan. The selected outcomes are:

   | Axis | Gate | Qualification | Limit | Over limit |
   | --- | --- | --- | --- | --- |
   | selected fixtures | accept `1` | accept `1` | accept `1` | scalar selection API rejects `2` as unreachable |
   | selected units | accept `1` | accept `1` | accept `1` | bridge unit cap rejects `2` |
   | selected domains | accept `1` | accept `1` | accept `1` | bridge domain cap rejects `2` |
   | scenarios | accept `32` | accept `512` | accept `4,096` | execution scenario cap rejects `4,097` |
   | operations in one scenario | accept `256` | accept `8,192` | 16-MiB plan cap wins at `65,536` | semantic expanded-action cap rejects `65,537` |
   | operations total | accept `1,024` | 16-MiB plan cap wins at `65,536` | 16-MiB plan cap wins at `1,000,000` | execution total-operation cap rejects `1,000,001` |
   | fibers total | accept `128` | accept `8,192` | 16-MiB plan cap wins at `65,536` | execution total-fiber cap rejects `65,537` |
   | simultaneously live fibers | accept `32` | accept `1,024` | accept `16,384` | execution live-fiber cap rejects `16,385` |
   | bindings | accept `2,048` through the sealed event profile | bridge event cap wins at `32,768` | VIAL 1-MiB source cap wins at `65,536` | VIAL 1-MiB source cap wins at `65,537` |
   | execution types | accept `512` through plain IAL1 | bridge type cap wins at `8,192` | VIAL 1-MiB source cap wins at `65,536` | VIAL 1-MiB source cap wins at `65,537` |
   | source-map records | accept `8,192` | 16-MiB plan cap wins at `262,144` | 16-MiB plan cap wins at `1,000,000` | execution source-map cap rejects `1,000,001` |
   | random attempts | accept `8,192` | accept `262,144` | accept `1,000,000` | deterministic exhaustion rejects `1,000,001` |
   | serialized plan bytes | accept exact 1 MiB | accept exact 4 MiB | accept exact 16 MiB | first additional complete operation record is rejected |

5. Construct total-fiber workloads as sequential bounded parallel groups, and
   construct live-fiber workloads as a depth-two tree with at most 256 children
   per parallel. This isolates total from simultaneous liveness and stays
   within the semantic per-parallel and nesting limits.
6. For random-attempt level `N`, compute the deterministic 64-bit candidate at
   zero-based attempt `N - 1`, author it as an equality constraint, and require
   the emitted attempt to equal `N - 1`. The one-over candidate targets attempt
   `1,000,000`, so the shipped generator exhausts exactly after its allowed
   million attempts. Generated and replayed decisions must retain equal keyed
   values and attempts; only their origin field may differ.
7. Use genuine referenced semantics for the byte axis. The version-1 AHB plan
   recipes are 2,974 reset operations plus scenario/endpoint identifier suffixes
   `41/2` for exactly 1,048,576 bytes; 12,166 plus `6/2` for exactly 4,194,304
   bytes; and 48,850 plus `106/2` for exactly 16,777,216 bytes. The endpoint
   alias remains referenced by its coverpoint. No comment, blank data, caller-
   supplied plan, path inflation, or opaque padding participates. One additional
   complete reset operation is the over-limit record.
8. Preflight minimum representation before high-count construction. Once a
   smaller canonical witness proves monotonic 16-MiB plan dominance, do not
   materialize a larger nominal limit merely to exhaust the host. Exact
   structural excess diagnostics remain opt-in, RAM-guarded qualification
   evidence.
9. Freeze the AHB source and bridge identities, plan/report hashes, source-map
   closure, logical `drive/sample/react/check` ordering, parallel join/cancel
   semantics, deterministic reruns, defensive projections, and repository-
   local staging cleanup as implementation oracles.

## Consequences

- Execution-scale generation can reach the one otherwise unreachable binding
  gate without turning private bridge qualification into a public planning or
  backend capability.
- Nominal execution limits are no longer mistaken for exercised limits when
  source, bridge, semantic, or serialized-plan authorities win first.
- The exact 1/4/16-MiB plans and million-attempt boundary are reproducible
  construction facts, not performance or capacity claims.
- Multi-fixture/unit/domain execution, backend emission, runtime, mixed
  language, native-UVM runtime, full-language coverage, whole-product
  `big`/`really_big`, and general parity remain unclaimed.

## Containment

This decision is one bounded rationale record under the existing decision
collection limits. It changes no product behavior; implementation remains the
separate `.17.2.4.2` owner.
