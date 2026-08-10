# 0055 — VIAL scale proof uses orthogonal workloads and stage-local oracles

- Date: 2026-08-10
- Type: verification architecture/scalability
- Status: accepted
- Refines: [0032](0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md), [0036](0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md), [0043](0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md)
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1`

## Context

The shipped VIAL pipeline has explicit resource caps from source parsing through
bridge, plan, backend artifacts, traces, and results, plus exact qualified
portable-SystemVerilog and VHDL tool profiles. It has no architecture-scale
qualification. One synthetic huge fixture would combine unrelated dimensions,
hide an earlier dominant cap, and make a failure impossible to attribute. Raw
timing without semantic or artifact oracles would also reward incorrect work.

## Decision

1. Prove architecture scale through six orthogonal families: semantic catalog,
   bridge fanout, execution graph, checking state, backend emission, and runtime
   stream. Vary one primary axis at a time and use one separately named,
   conservative balanced interaction workload.
2. Give every axis reference, gate-candidate, qualification-candidate, exact-
   limit, and over-limit levels. Candidate labels make no support claim before
   implementation, measurement, and promotion.
3. Require stage-local correctness, determinism, source-map, artifact, semantic-
   result, failure, and cleanup oracles. A failed oracle invalidates the
   performance sample.
4. Keep architecture-scale evidence distinct from whole-product `big` /
   `really_big`, multi-unit/domain, mixed-language, native-UVM runtime, full-
   language, synthesis, and general-parity claims.
5. Apply decision `0056` to measurement, resource safety, evidence-derived
   budgets, graceful failure, project-data locality, cleanup, and promotion.

## Consequences

- A failure names the stage and growing semantic family instead of merely
  reporting that a large fixture failed.
- Workload construction and correctness proof remain separate from measurement,
  cap repair, and gate promotion.
- Candidate profiles cannot become capacity claims by naming alone.

## Selected Contract

The following version-1 contract is normative for the implementation leaves.
Its selection changes no parser, IR, bridge, emitter, tool, artifact,
capability, support record, or scale claim.

## Outcome

Architecture scale is proved with deterministic, orthogonal workload families,
stage-local correctness oracles, and evidence-derived performance budgets. One
large fixture is not sufficient evidence: it can hide which stage or semantic
family grew, trigger an earlier unrelated cap, and turn a local regression into
an uninterpretable whole-pipeline failure.

The version-1 proof has six workload families:

```text
semantic_catalog_v1   -> parse, validate, VIALSemanticIR
bridge_fanout_v1      -> canonical HIAL route, HIALVIALBridgeManifest
execution_graph_v1    -> bind, elaborate, immutable VIALExecutionIR
checking_state_v1     -> models, scoreboards, coverage, faults, decisions
backend_emission_v1   -> portable SV/VHDL/OSVVM artifact graphs
runtime_stream_v1     -> qualified compile, run, trace, result
```

Each generated workload varies one primary axis while retaining the smallest
valid anchor for every other axis. A separately named balanced workload checks
interactions at conservative cardinalities; it is not used to discover an
individual limit. This avoids accidental Cartesian expansion and makes the
first failing stage and resource attributable.

This selection changes no parser, IR, bridge, emitter, tool, artifact,
capability, support record, or scale claim. `.17.2` owns workload construction
and structural oracles; `.17.3` owns measurements; `.17.4` owns missing or
incorrect limit enforcement; `.17.5` alone may promote measured profiles into
stable gates and user-visible capacity guidance.

## Authority And Scope

This contract measures the shipped HIAL/VIAL architecture:

```text
.vial + canonical HIAL review route
  -> VIALSemanticIR + HIALVIALBridgeManifest
  -> VIALExecutionIR
  -> portable backend artifacts
  -> qualified external-tool execution where applicable
  -> closed trace and normalized result
```

It does not qualify the complete FSMGen user path, multiple HIAL units or clock
domains, arbitrary VIAL language breadth, full SystemVerilog/UVM/VHDL, mixed
language, general cross-backend parity, synthesis scale, or the `big` and
`really_big` product profiles. Those remain with
`FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY` and their exact backend owners.

The current `core_single_unit_v1` bridge and
`core_directed_single_clock_execution_v1` plan accept exactly one selected
fixture, unit, and domain. Their scale axis is therefore `1` accepted and `2`
rejected. Repeating one-unit measurements does not establish multi-unit or
multi-domain support.

## Immutable Workload Specification

Every generated workload is described by
`fsmgen.vial_architecture_scale_workload.v1` with exactly:

```text
schema
schema_version
family
level
primary_axis
requested_counts
expected_stage
expected_outcome
generator_revision
seed
anchor_identity
source_route
backend_profile
tool_profile
applicable_oracles
explicit_nonclaims
```

`seed` is the unsigned integer `1701` for version 1. It selects payload values
only; it never selects structure, names, ordering, workload counts, or the
expected outcome. Stable names are derived from family, axis, and zero-padded
ordinal. Payload generation uses the already-selected VIAL SHA-256 counter /
rejection algorithm. No host randomness, current time, process ID, temporary
path, filesystem enumeration order, or thread schedule enters workload bytes.

The workload identity is the SHA-256 of canonical JSON containing the complete
specification plus ordered input-content digests. Measurements, absolute paths,
host identity, tool-discovery paths, timestamps, and run ordinals never enter
that identity. Two constructions of one specification must produce byte-equal
inputs and equal stage identities before any performance result is accepted.

Scale-only source and artifacts are generated under repository-derived staging;
they are not checked-in product examples. A generator must construct every
stage through its canonical producer. It may not forge a `VIALSemanticIR`,
bridge manifest, execution plan, backend manifest, trace, or result merely to
reach a desired count.

## Levels And Claim States

Every primary axis uses these levels:

| Level | Purpose | Claim state |
| --- | --- | --- |
| `reference_v1` | checked AHB source and HIAL route | already functionally qualified only at its recorded bounded profile |
| `gate_candidate_v1` | conservative always-on correctness/performance candidate | unqualified until `.17.3` measurement and `.17.5` promotion |
| `qualification_candidate_v1` | heavier opt-in architecture exercise | unqualified until `.17.3` measurement and `.17.5` publication |
| `limit_v1` | exact declared structural boundary, under safety preflight | limit-conformance evidence only, never a performance gate |
| `over_limit_v1` | boundary plus one or first representable excess | must fail at the earliest authoritative stage |

`reference_v1` is the checked
`vial/ahb_subordinate_base_output_arbitration.vial` route. Its authored VIAL
source is 4,986 bytes / 123 lines / SHA-256
`2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd`.
Its checked plan contains one fixture, unit, and domain; two scenarios; 21
operations; four total and three simultaneously live fibers; 22 bindings;
nine execution types; two models and scalar state cells; one capacity-four
scoreboard; one coverpoint with two bins; one fault; one random occurrence; and
39 plan source-map records. These are a correctness anchor, not a scale claim.

## Semantic Catalog Family

`semantic_catalog_v1` uses normal `.vial` source and the public parser/validator.
The generator keeps declarations referenced and type-correct; unused padding,
comments, blank data, and duplicated unreachable syntax do not count as scale.

| Primary axis | Gate candidate | Qualification candidate | Limit | Over limit |
| --- | ---: | ---: | ---: | ---: |
| imports | 8 | 32 | 64 | 65 |
| declarations in one package section | 128 | 1,024 | 4,096 | 4,097 |
| fixtures in one package | 32 | 256 | 1,024 | 1,025 |
| actions in one scenario after literal-repeat accounting | 1,024 | 16,384 | 65,536 | 65,537 |
| nested parallel depth | 4 | 12 | 16 | 17 |
| fibers in one parallel | 32 | 128 | 256 | 257 |
| scalar or list length | 4,096 | 32,768 | 65,536 | 65,537 |
| record fields | 32 | 128 | 256 | 257 |
| aggregate depth | 8 | 24 | 32 | 33 |
| scoreboard capacity | 4,096 | 262,144 | 1,000,000 | 1,000,001 |
| coverage maximum bins | 4,096 | 262,144 | 1,000,000 | 1,000,001 |
| literal repeat count | 4,096 | 262,144 | 1,000,000 | 1,000,001 |

Source bytes use the existing exact limits: 1,048,576 bytes per source and
16,777,216 combined bytes. Those are independent byte axes populated with
valid referenced declarations of deterministic bounded width. Over-limit byte
inputs append one complete valid declaration until the first whole encoded
record exceeds the cap; irrelevant text padding is forbidden.

For parallel-depth scale, only one child continues nesting and the sibling is a
minimal valid action. This isolates depth from exponential fiber growth. For
fibers-per-parallel scale, nesting remains one. Literal repeats test checked
counting before materialization; they must not allocate the expanded operation
graph in the semantic stage.

Semantic correctness requires exact package/declaration/fixture/action/fiber
counts, unique stable semantic IDs, complete in-bounds spans, closed resolved
references and types, stable authored order, equal sanitized reports, and
byte-equal canonical formatting on two independent constructions.

## Bridge Fanout Family

`bridge_fanout_v1` uses direct IAL0 or direct IAL1 only through the shipped
builder. Endpoint-only probes may use a deterministic direct-IAL0 actor.
Transactions, events, probes, types, configuration, and backend bindings use a
generated, reparsed direct-IAL1 `(verification-bridge ...)` annotation. IAL2
scale remains constrained to the canonical `.ppif -> generated .isf -> .fsm`
review route and never bypasses generated IAL1.

| Primary axis | Gate candidate | Qualification candidate | Limit | Over limit |
| --- | ---: | ---: | ---: | ---: |
| selected units | 1 | 1 | 1 | 2 |
| selected domains | 1 | 1 | 1 | 2 |
| configurations | 256 | 2,048 | 4,096 | 4,097 |
| types | 256 | 2,048 | 4,096 | 4,097 |
| endpoints | 256 | 2,048 | 4,096 | 4,097 |
| transactions | 32 | 192 | 256 | 257 |
| events | 256 | 1,536 | 2,048 | 2,049 |
| observations | 32 | 192 | 256 | 257 |
| probes | 32 | 192 | 256 | 257 |
| backend bindings | 2,048 | 12,288 | 16,384 | 16,385 |
| retained residue records | 256 | 2,048 | 4,096 | 4,097 |
| source-map records | 8,192 | 49,152 | 65,536 | 65,537 |

Each axis specification targets the normalized manifest count, not merely an
authored-line count. The generator must account for mandatory anchor records
and assert the exact post-builder value. The existing 16,777,216-byte
serialized-manifest cap is a separate byte axis. If a byte cap necessarily
precedes a requested structural count, the expected outcome names that earlier
cap; the run cannot claim the later count was exercised.

Bridge correctness requires the exact canonical HIAL route, immutable
defensive data, unique stable IDs, complete source/review identities, every
VIAL reference resolved, every semantic field mapped, target bindings closed
over their endpoints/types/domains, and byte-equal manifest/report projection
on rerun. A direct IAL2-to-bridge path is always a test failure.

## Execution Graph Family

`execution_graph_v1` consumes a successful generated SemanticIR and bridge
through the shipped binder. It varies operational topology without target
backend terms.

| Primary axis | Gate candidate | Qualification candidate | Limit | Over limit |
| --- | ---: | ---: | ---: | ---: |
| selected fixtures / units / domains | 1 / 1 / 1 | 1 / 1 / 1 | 1 / 1 / 1 | 2 on exactly one selected axis |
| scenarios | 32 | 512 | 4,096 | 4,097 |
| operations in one scenario | 256 | 8,192 | 65,536 | 65,537 |
| operations total | 1,024 | 65,536 | 1,000,000 | 1,000,001 |
| fibers total | 128 | 8,192 | 65,536 | 65,537 |
| simultaneously live fibers | 32 | 1,024 | 16,384 | 16,385 |
| bindings | 2,048 | 32,768 | 65,536 | 65,537 |
| execution types | 512 | 8,192 | 65,536 | 65,537 |
| source-map records | 8,192 | 262,144 | 1,000,000 | 1,000,001 |
| random attempts | 8,192 | 262,144 | 1,000,000 | 1,000,001 |

The serialized plan cap remains 16,777,216 bytes. Requested high-count runs
must first estimate their minimum representation and execute only under the
RAM/time safety controls below. When plan bytes or another earlier resource
limit dominates, the report records the requested axis, reached count, and
authoritative earlier diagnostic. A killed or exhausted host is never accepted
as evidence of the declared structural cap.

Execution correctness requires exact scenario/operation/fiber/binding/type and
source-map counts, stable IDs and ranks, no ambiguous drive, exact
drive/sample/react/check ordering, exact parallel join/cancel semantics,
stable keyed random decisions and replay, equal defensive reports, and equal
plan hashes on rerun. Timing/RSS values are not part of the plan or replay
identity.

## Checking-State Family

`checking_state_v1` keeps scenario topology conservative while scaling stateful
verification services.

| Primary axis | Gate candidate | Qualification candidate | Limit | Over limit |
| --- | ---: | ---: | ---: | ---: |
| model instances | 32 | 1,024 | 4,096 | 4,097 |
| scalar model-state cells | 512 | 32,768 | 65,536 | 65,537 |
| scoreboard instances | 32 | 1,024 | 4,096 | 4,097 |
| total declared scoreboard capacity | 4,096 | 262,144 | 1,000,000 | 1,000,001 |
| coverpoints | 256 | 8,192 | 65,536 | 65,537 |
| bins plus explicit cross tuples | 4,096 | 262,144 | 1,000,000 | 1,000,001 |
| faults | 32 | 1,024 | 4,096 | 4,097 |
| random occurrences | 1,024 | 32,768 | 65,536 | 65,537 |

Crosses enumerate only explicitly declared tuples; there is no implicit
Cartesian expansion. Scoreboards use bounded declared capacity and exercise
enqueue/match/drain; allocating unused queue capacity is not a runtime-state
proof. Model cells are read and updated. Coverpoints are sampled, faults are
activated and restored, and random occurrences are represented in replay.

Correctness requires the exact expected final model state, maximum and final
scoreboard depths, zero pending expected/actual entries, exact coverage hit
vector, exact fault activation/restoration records, exact decision values and
replay identity, and an equal normalized semantic projection on rerun.

## Balanced Candidate

`balanced_portable_v1` is the only multi-axis candidate. It uses one unit and
domain; 128 endpoints; 16 transactions; 128 events; 32 probes; 32 scenarios;
1,024 total operations; 128 total and 32 simultaneously live fibers; 2,048
bindings; 512 execution types; 32 models with 512 scalar cells; 32
scoreboards with total capacity 4,096; 256 coverpoints with 4,096 total bins;
32 faults; and 1,024 random occurrences.

The candidate checks ordinary interaction between families after every
orthogonal `gate_candidate_v1` passes. It is not a boundary workload and its
numbers are not supported capacity until `.17.3` measures it and `.17.5`
promotes it.

## Backend Emission Family

Backend workloads consume an already-proved execution graph. Version 1 freezes
these structural authorities:

| Profile | Current structural boundary |
| --- | --- |
| `sv_portable_verilator` | 3 backend artifacts plus one DUT artifact per selected unit; 16,777,216 generated-SV bytes; 1,000,000 source-map entries |
| `vhdl_portable_ghdl` | one selected unit/domain; 6 generated sources; 17 total artifacts; 16,777,216 generated bytes; 59 canonical source maps are the reference shape |
| `vhdl_osvvm_qualified` | portable graph plus 7 generated provider sources; exact OSVVM 2026.05 materialization remains external input, not generated scale data |
| `sv_uvm_emit.accellera_2020_3_1` | one selected unit/domain; 10 generated sources; 16 total artifacts; 16,777,216 generated bytes; emission/review only |

Portable SV, portable VHDL, and OSVVM execution are eligible for `.17.3` only
under their exact qualified tools. Native UVM is eligible only for emission and
static review; its experimental tool probe cannot qualify scale runtime.

Emission correctness requires exact artifact inventory, repository-relative
paths, stable ordering, no monolithic cross-unit file, complete source-map
closure, stable generated identifiers, exact HIAL source identity, byte-equal
rerun, static backend checks, and no target artifact before successful
negotiation. Generated lines/bytes are measured outputs, never inflated with
padding to reach a number.

## Runtime Stream Family

`runtime_stream_v1` varies semantic activity that produces closed trace and
result records. Target counts are 10,000 records for `gate_candidate_v1` and
100,000 for `qualification_candidate_v1`. They are candidates until actual
compile/run evidence proves that the workload reaches the exact count and
retains its semantic oracle.

The portable-SV structural trace cap is 8,000,002 records and 67,108,864 bytes;
the first reached cap is authoritative. Because a valid JSONL record can make
the byte limit dominate, no test may claim the record boundary unless it
actually reaches it within the byte cap. The normalized result cap remains
67,108,864 bytes.

The `sv_portable_verilator` Runner enforces 120 seconds and 8,388,608 captured
bytes for compile, then 30 seconds and 67,108,864 captured bytes for runtime.
Those values agree with the normative portable-backend contract. The public
support snapshot currently reports 4,194,304 bytes for each transcript; this
is historical support-accounting drift introduced with the Runner, not an
enforced limit. Proposed leaf `.17.6` owns alignment before scale automation
may consume that snapshot.

Runtime correctness requires qualified tool identity, successful compile and
elaboration, closed header/footer framing, exact record count and byte count,
valid source/operation identities, exact logical outcomes, passing normalized
result, deterministic semantic projection, atomic publication, and complete
removal of the operation-owned staging tree. Performance metadata may differ;
semantic/result data may not.

## Stage Oracles

Every run records all applicable oracles independently:

| Stage | Required oracle |
| --- | --- |
| construct | workload specification and generated inputs are byte-identical across two constructions |
| semantic | expected counts, IDs, spans, references, types, limits, and report projection |
| bridge | canonical review route, exact counts, resolved facts/bindings, provenance, maps, defensive projection |
| plan | exact graph counts and ranks, logical-time invariants, replay identity, plan hash |
| emit | exact artifact inventory, source-map closure, static checks, byte-identical sources |
| compile | exact qualified tool/profile/command, bounded success, expected top/artifacts, sanitized transcript |
| run | closed trace, expected semantic streams/counts/outcomes, passing normalized result |
| failure | exact code/path/stage, no partial publication, exact owned cleanup, no host exhaustion |

A performance sample is invalid when any correctness oracle fails. A fast
incorrect run, partial artifact graph, killed process, or stale support claim
is not scale evidence.
