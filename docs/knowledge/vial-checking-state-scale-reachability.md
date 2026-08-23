---
id: vial-checking-state-scale-reachability
title: VIAL checking-state scale uses packed semantic oracles at each reachable level
answers:
  - "which VIAL checking-state scale levels are reachable?"
  - "how does VIAL prove a scoreboard reaches and drains one million entries?"
  - "how does VIAL prove an exact one million entry coverage hit vector?"
  - "what is the VIAL checking-state coverpoint source boundary?"
  - "what is the VIAL checking-state random occurrence plan boundary?"
  - "why does checking-state scale not use the portable SystemVerilog backend as its oracle?"
  - "does a VIAL cross enumerate explicit tuples or a static Cartesian bin domain?"
  - "what does preflight_dominated mean for checking-state random occurrences?"
  - "how are VIAL model-instance scale levels executed and checked?"
  - "how does VIAL prove every scalar model-state cell changes?"
  - "how does VIAL prove fault activation, expiry, and restoration at scale?"
  - "how are VIAL Runner capture limits and nonzero tool exits kept fail closed?"
date: 2026-08-23
status: current
tags: [vial, checking-state, scale, scoreboard, coverage, faults, randomness]
evidence: >-
  docs/decisions/0073-checking-state-scale-uses-packed-state-oracles-and-static-cross-domains.md;
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md;
  docs/VIAL_EXECUTION_IR_V1_CONTRACT.md;
  perl/FSM/VIAL/SemanticBuilder.pm; perl/FSM/VIAL/ExecutionBuilder.pm;
  perl/FSM/VIAL/ArchitectureScaleCheckingState.pm;
  perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Backend/ResultProducer.pm;
  perl/FSM/Support/VIALExecutionContract.pm;
  t/1629-vial-architecture-scale-checking-foundation.t;
  t/1630-vial-architecture-scale-checking-models.t;
  t/1631-vial-architecture-scale-checking-scoreboards.t;
  t/1632-vial-architecture-scale-checking-coverage.t;
  t/1633-vial-architecture-scale-checking-faults.t;
  t/1634-vial-architecture-scale-checking-random-replay.t;
  t/1635-vial-architecture-scale-checking-qualification.t;
  perl/FSM/VIAL/Backend/Runner.pm;
  t/1640-vial-runner-capture-limits.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1629-vial-architecture-scale-checking-foundation.t t/1630-vial-architecture-scale-checking-models.t t/1631-vial-architecture-scale-checking-scoreboards.t t/1632-vial-architecture-scale-checking-coverage.t t/1633-vial-architecture-scale-checking-faults.t t/1634-vial-architecture-scale-checking-random-replay.t t/1635-vial-architecture-scale-checking-qualification.t t/1640-vial-runner-capture-limits.t &&
  rg -n 'checking_state_v1|one_bound_event_occurrence_per_instance_v1|packed_complete_transaction_fifo_v1|one_sample_packed_static_domain_vector_v1|arm_apply_expire_restore_each_fault_v1|generate_replay_compare_each_keyed_boolean_v1|coverage_bins_and_cross_tuples|random_occurrences|serialized_plan_bytes|cross Cartesian product' docs/decisions/0073-checking-state-scale-uses-packed-state-oracles-and-static-cross-domains.md perl/FSM/VIAL/ArchitectureScaleCheckingState.pm perl/FSM/VIAL/SemanticBuilder.pm perl/FSM/VIAL/ExecutionBuilder.pm perl/FSM/Support/VIALExecutionContract.pm
---

Decision `0073` selects one outcome for every non-reference level before the
checking-state generator is implemented:

| Axis | Accepted levels | First earlier-cap level |
|---|---|---|
| model instances | 32 / 1,024 / 4,096 | 4,097 at `/models` |
| scalar state cells | 512 / 32,768 / 65,536 | 65,537 at `/models` |
| scoreboard instances | 32 / 1,024 / 4,096 | 4,097 at `/scoreboards` |
| scoreboard capacity | 4,096 / 262,144 / 1,000,000 | 1,000,001 at the semantic capacity bound |
| coverpoints | 256 / 8,192 | 65,536 is envelope-unconstructible |
| bins plus cross tuples | 4,096 / 262,144 / 1,000,000 | 1,000,001 at `/coverage` |
| faults | 32 / 1,024 / 4,096 | 4,097 at `/faults` |
| random occurrences | 1,024 | 32,768 and 65,536 hit plan bytes; 65,537 hits its count cap |

The coverpoint route accepts 9,524 declarations in 1,048,467 source bytes and
rejects 9,525 in 1,048,577 bytes at the 1,048,576-byte parser cap. Selected
65,536/65,537 sources cross the scale constructor's 1,114,112-byte envelope,
so decision `0072` requires an `envelope_unconstructible` result plus the
separate measured 9,524/9,525 product boundary.

Compact Boolean random sources parse at all selected levels. The exact plan
route accepts 8,440 occurrences in 16,775,415 bytes and rejects 8,441 at the
16,777,216-byte serialized-plan cap. The full 32,768 qualification returns the
same `/plan` diagnostic. The million-level scoreboard proof therefore cannot
be represented as one operation per enqueue; it uses the qualification-only
packed-state evaluator instead.

The first exact measurement capture to reach that qualification proves why the
cap must be enforced earlier without changing its contract. Canonical
evaluation returns the historical `/plan` rejection, but the measured
bind-plan stage times out after 300 seconds because the builder constructs the
complete 32,768-decision plan before checking serialized bytes. Active child
`.17.3.3.2.3` owns a general compact plan-projection byte preflight whose result
must equal terminal canonical serialization for accepted plans; the terminal
check remains. A hard-coded 8,440/8,441 occurrence threshold is explicitly not
an admissible repair. The revision-`e4b95dbd` interruption prefix is preserved
under its revision-keyed same-volume archive with an independently reconstructed
57-report manifest; active execution/checking evidence and raw staging are
empty before implementation.

That evaluator consumes caller-sealed canonical SemanticIR and ExecutionIR. A
one-million-entry scoreboard stores only its varying 32-bit payload in a
4,000,000-byte packed FIFO, compares every reconstructed complete transaction,
reaches exact maximum depth 1,000,000, and drains to zero. Coverage uses one bit
per static bin or tuple, so an exact million-entry hit vector occupies 125,000
bytes and can be byte-compared without a million JSON records.

VIAL v1 has no tuple-list syntax. An explicitly authored `cross` names its
points, and the Cartesian product of those points' explicitly authored bins is
the complete static tuple domain required by the older source/execution
contracts and current builders. No backend may create an undeclared bin, cross,
or tuple outside that domain. Two 999-bin points plus their 998,001-tuple cross
and one independent bin make exactly 1,000,000 entries in a 62,841-byte source;
one sample hits the exact all-one vector because every authored bin matches.

`TraceValidator`, `ResultProducer`, and the first portable SystemVerilog backend
remain result/profile machinery, not general checking-state semantic oracles.
The implemented model, scoreboard, coverage, fault, and random/replay slices
publish exactly 32 non-reference shapes across all eight axes. They reject reference,
non-owned, unknown-level, IR, trace, result, and support-metadata injection.
Its same-package-only candidate route accepts just ordinary VIAL text plus the
exact checked-AHB source, regenerates the workload defensively, and reaches
canonical SemanticIR, bridge, ExecutionIR, and plan twice with content-addressed
workload/evaluation/rerun identities. The frozen foundation witness still
reports `accepted_not_axis_evaluated`; generated accepted shapes populate only
their model, scoreboard, coverage, fault, or random/replay compartment and explicitly deny every capability,
support, performance, capacity, backend, or runtime claim.

That foundation freezes the selected packed representations before an axis is
owned: fixed-width model cells reject unknown state; scoreboard payload is a
big-endian 32-bit FIFO capped at 1,000,000 entries/4,000,000 bytes and requires
complete transaction reconstruction; coverage is an LSB-first bit vector capped
at 1,000,000 entries/125,000 bytes and requires independent byte equality.
Canonical regeneration rejects construction/evaluation mutation, and common
same-volume staging removes the exact content-addressed directory after both
success and consumer failure.

The model-instance renderer reuses one one-byte counter definition at 32,
1,024, and 4,096 instances. The scalar-cell renderer uses 32 instances of a
16-, 1,024-, or 2,048-cell definition to reach 512, 32,768, or 65,536 cells;
the adjacent excess adds one singleton definition and instance to reach exactly
65,537 while its source remains inside the construction envelope. The oracle
accepts only the canonical known u8 `0 + 1` rule, derives each instance's bound
`accepted` event from ExecutionIR, synthesizes one occurrence per instance,
then initializes, commits, and reads every cell. Packed initial and final bytes
must equal independently derived all-zero and all-one vectors. Hostile
known-mask mutation fails this oracle. The 4,097-instance and 65,537-cell routes each
return exactly one `VIAL_EXECUTION_LIMIT_ERROR` at `/models` and no downstream
identity. The complete high-count sweep passes under the repository RAM guard.

The scoreboard-instance renderer reuses one capacity-one in-order definition
at 32, 1,024, and 4,096 instances. The capacity renderer uses one definition
and one instance at 4,096, 262,144, and 1,000,000 entries. The oracle stores
only each entry's varying big-endian uint32 payload, reconstructs the other five
fixed transaction fields, compares all six fields, preserves FIFO order, and
drains expected and actual depth to zero. At one million entries it performs
6,000,000 field comparisons over exactly 4,000,000 bytes with digest
`a515ca39768fa0e597911d6564fa44f9163ecf81559ecc776c16f751f29b2b65`.
Mismatch, at-capacity enqueue, packed-byte corruption, hostile in-order-policy
mutation, source mutation, and report mutation all fail closed.

The 4,097-instance route returns exactly one
`VIAL_EXECUTION_LIMIT_ERROR` at `/scoreboards`, retaining only semantic and
bridge identities. Capacity 1,000,001 returns exactly one parser
`VIAL_LIMIT_ERROR` at `/packages/0/scoreboards/0/capacity` and no stage
identity. The default and complete RAM-guarded scoreboard sweeps pass. This
implementation changes no product behavior, support state, performance budget,
or capacity claim.

The coverage renderer owns all eight coverpoint/static-domain shapes. It emits
exactly 110 bytes per coverpoint plus 827 fixed bytes, so the selected
65,536/65,537 sources return source-free `envelope_unconstructible` results
with the exact input-1 fixture diagnostic and separately retain the measured
9,524/9,525 parser boundary. Reachable coverpoints and authored bin/cross
domains traverse the canonical route twice. Their provider-free oracle sets one
LSB-first bit per authored bin or static tuple, independently reconstructs both
the all-hit bytes and authored order, and rejects illegal/ignore, bit, order,
source, and report mutations. The million case is exactly 1,999 bins plus
998,001 tuples in 62,841 source bytes and 125,000 vector bytes, with vector
digest `ae450c2064c76df34378b11784d1d24bde068c9b94dab52cc41fcea3be558582`;
one further 29-byte bin returns only `VIAL_EXECUTION_LIMIT_ERROR` at
`/coverage`. Default and exact RAM-guarded `t/1632` pass.

The fault renderer owns all four selected levels. Accepted 32/1,024/4,096
sources bind every declaration to the checked AHB write transaction's `size`
field, substitute known three-bit value `7` for original `2`, and retain the
authored one-`bus`-interval lifetime. The provider-free oracle validates those
facts from canonical ExecutionIR and streams arm, apply, expire, and restore
records in stable declaration order into actual and independently reconstructed
digests. At the 4,096 limit it proves exactly 16,384 transitions with digest
`4042b666fd911ef3b7d39fe6abeb721c96ade2f322461f3845558ddf1e648dc9`
without retaining a per-fault report array. Armed reinjection, active overlap,
substitute mutation, declaration-order mutation, source mutation, and report
mutation fail closed. Fault 4,097 returns exactly one
`VIAL_EXECUTION_LIMIT_ERROR` at `/faults` and no execution/plan identity.
Default and exact RAM-guarded `t/1633` pass.

The random renderer uses a bounded palette of 128 Boolean choices and counts
each referenced `(scenario, choice)` pair as one real occurrence. The 1,024
gate therefore contains eight scenarios and produces an exact 2,073,805-byte
plan. Independent generation reproduces every keyed value, strict replay uses
the canonical manifest, and origin-free generated/replayed decision sequences
and plans compare byte-equal; value and order mutations fail closed. The full
32,768 semantic route returns only `VIAL_EXECUTION_LIMIT_ERROR` at `/plan`.
The 65,536 level reports `preflight_dominated` / `not_materialized` with no
stage identity or selected-count claim, while 65,537 reaches the exact
`/randomness/decisions` count diagnostic. Opt-in RAM-guarded evidence accepts
8,440 occurrences in a 16,775,415-byte plan and rejects adjacent 8,441. Default
`t/1635` independently freezes the whole family as exactly 32 owned selected
shapes plus eight rejected `reference_v1` records, byte-equal gate reports,
hostile-caller rejection, explicit product nonclaims, and exact same-volume
cleanup. Guarded default `t/1629`-`t/1635` passes at Files=7/Tests=36 in 166
seconds; the complete exact `t/1630`-`t/1634` matrix passes at Files=5/Tests=27
in 593 seconds under the 4,096-MiB guard.

Focused `t/1640` now proves Runner's aggregate exact/one-over capture boundary
and that successful capture infrastructure cannot accept a nonzero tool exit;
public contract and integration tests retain the shipped ceiling values.
