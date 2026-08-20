# 0073 — Checking-state scale uses packed-state oracles and static cross domains

- Date: 2026-08-20
- Type: verification architecture/scalability
- Status: selected by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1`
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0072](0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md)
- Implementation owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`

## Context

The eight `checking_state_v1` axes do not share one execution route. Ordinary
VIAL parsing and the unchanged `ExecutionBuilder` can carry the selected model,
scoreboard, fault, and compact coverage declarations, but they do not execute
the stateful services. `TraceValidator` validates closed record shape, known
identities, ordering, and bounded scalar fields; `ResultProducer` projects those
validated records and derives aggregate metrics. Neither recomputes model
transitions, scoreboard queue contents, coverage matches, or fault lifetimes,
so accepting a self-reported trace would be a circular scale oracle. The first
portable SystemVerilog backend is also intentionally narrower: it uses the first
model state cell, one Boolean scoreboard slot for the first instance, and its
selected Boolean coverage profile. It cannot be borrowed as a general
checking-state reference engine or a support claim.

Bounded, repository-local probes through ordinary parsing, the canonical AHB
bridge, and the public execution builder establish this level matrix. A check
means that the level must also pass the provider-free state oracle selected
below; an earlier-cap result never claims that oracle ran.

| Axis | Gate | Qualification | Limit | Over limit |
| --- | --- | --- | --- | --- |
| model instances | 32 check | 1,024 check | 4,096 check | execution cap at `/models` |
| scalar model-state cells | 512 check | 32,768 check | 65,536 check | execution cap at `/models` |
| scoreboard instances | 32 check | 1,024 check | 4,096 check | execution cap at `/scoreboards` |
| declared scoreboard capacity | 4,096 check | 262,144 check | 1,000,000 check | semantic capacity bound |
| coverpoints | 256 check | 8,192 check | source-envelope result | source-envelope result |
| bins plus cross tuples | 4,096 check | 262,144 check | 1,000,000 check | execution cap at `/coverage` |
| faults | 32 check | 1,024 check | 4,096 check | execution cap at `/faults` |
| random occurrences | 1,024 check | plan cap | plan cap | random-occurrence cap |

The coverpoint renderer reaches 9,524 coverpoints in 1,048,467 source bytes;
9,525 produces 1,048,577 bytes and is rejected by the 1,048,576-byte parser
cap. Its selected 65,536/65,537 sources are 7,209,787/7,209,897 bytes, so the
1,114,112-byte construction envelope decides before parsing. Those levels use
decision `0072`'s `envelope_unconstructible` / `not_constructed` treatment and
carry the 9,524/9,525 product-route boundary separately.

Random source is not the obstacle. A compact valid Boolean encoding produces
32,768/65,536/65,537 occurrences in 470,412/933,555/933,642 bytes, and all
three parse. The gate produces 1,024 decisions in a 2,073,805-byte plan. The
whole-route boundary is adjacent: 8,440 occurrences produce a 16,775,415-byte
plan, while 8,441 returns `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message
`serialized_plan_bytes exceeds the limit 16777216`, at `/plan`. The 32,768
qualification was also run through the full route and returns that exact
diagnostic. The 65,536 limit is therefore `preflight_dominated` by the adjacent
plan witness; 65,537 reaches its own random-occurrence cap before plan
serialization.

One contract sentence needed reconciliation before a coverage oracle could be
selected. Decision `0055` says crosses enumerate explicitly declared tuples and
forbids implicit Cartesian expansion, but VIAL v1 has no tuple-list syntax.
The older source and execution contracts instead define a declared cross by its
explicit point list, require the Cartesian product of those points' explicit
bins to fit `max_bins`, and forbid a backend from adding an undeclared bin,
cross, or tuple outside that static domain. `SemanticBuilder` and
`ExecutionBuilder` implement that older contract by computing the product.
The scale sentence cannot literally be implemented and must not silently turn
into a different language.

The reconciled static-domain reading makes the million level compact and exact.
Two explicitly declared 999-bin Boolean coverpoints and their explicitly
declared cross contribute 1,998 bins plus 998,001 tuples; one independent bin
makes exactly 1,000,000. Because every bin explicitly matches the same sampled
value, one check-phase sample hits the entire static vector. The canonical
route accepts this 62,841-byte source and a 27,626-byte plan. A second
independent bin makes 1,000,001 in 62,870 bytes and returns exactly
`coverage_bins_and_cross_tuples exceeds the limit 1000000` at `/coverage`.
The 4,096 and 262,144 levels use the same construction principle and also
accept. This is an explicitly authored cross over explicitly authored bins,
not a runtime- or backend-invented cross.

## Decision

1. **Keep all selected levels and report the earliest authority.** The table
   above is the required implementation boundary. Reference profiles remain
   catalog records rather than generated checking shapes. An accepted
   declaration is not enough: every `check` cell must run the exact state oracle.
   Earlier source, semantic, execution-resource, or plan caps are successful
   expected outcomes only when their exact diagnostic, path, absent downstream
   identity, and applicable decision-`0072` boundary record all match.
2. **Refine `0055` to the shipped static-cross contract.** An authored VIAL v1
   `cross` explicitly selects its points. The Cartesian product of those
   points' explicitly authored bins is its complete, statically bounded tuple
   domain. No tuple exists without an authored cross and authored bins, and no
   backend may add or expand beyond that domain. “Explicit tuple” in the scale
   contract means a member of this statically declared domain; it does not
   introduce tuple-list syntax that VIAL v1 does not have. This closes the
   documentation defect without changing parser, IR, or runtime behavior.
3. **Add one provider-free, qualification-only checking-state evaluator.** It
   consumes the caller-sealed workload plus exact canonical SemanticIR and
   ExecutionIR. It cannot accept caller-created IR, traces, backend results, or
   support metadata. It reconstructs model rules, scoreboard definitions,
   coverage bins/crosses, faults, and keyed random decisions from those immutable
   inputs, executes a deterministic axis-local checking program, and returns a
   content-addressed bounded report. It is test infrastructure, not a public
   simulator, backend, result producer, or new capability.
4. **Exercise state in packed form.** Model cells use fixed-width packed values.
   The scoreboard-capacity program enqueues one million complete deterministic
   transactions, reaches exact depth 1,000,000, then matches and drains them in
   order to zero; only the varying 32-bit payload is stored, while the other
   normalized fields are fixed and compared on reconstruction. This bounds the
   queue payload at 4,000,000 bytes. Coverage uses a one-bit-per-static-bin-or-
   tuple vector, so the million-entry vector occupies 125,000 bytes; it must be
   byte-compared with the independently derived all-hit vector. Packed state is
   an implementation representation, not a shortcut around enqueue, compare,
   sample, hit, expire, or restoration semantics.
5. **Keep exact semantic oracles axis-local.** Model workloads trigger and read
   every selected state cell. Every scoreboard instance enqueues, matches, and
   drains. Coverage compares the exact ordered bit vector and hit count. Every
   fault is armed, substituted, expired, and proved restored. Random workloads
   compare keyed generated decisions, replay values, replay identity, and the
   normalized rerun projection. The evaluator must include hostile-state and
   caller-seal negatives and deterministic byte-equal reruns.
6. **Do not use public runtime traces as the scale report.** A million JSON
   coverage or scoreboard records would spend the runtime trace budget on proof
   transport, while accepting fewer self-reported records would weaken the
   oracle. The bounded qualification report carries counts, maximum/final
   depths, packed-vector identities, state digests, decision/replay identities,
   and endpoint witnesses; exact equality is established inside the evaluator
   before the report is produced.
7. **Keep expensive route evidence opt-in and preflight dominated.** The
   8,440/8,441 random boundary and any full high-count route remeasurement run
   only under `scripts/run_with_ram_guard.sh`. Once the exact smaller witness
   proves the unavoidable 16-MiB plan rejection, a larger selected level may
   report `preflight_dominated` / `not_materialized` rather than allocate a plan
   known to fail. The one-million scoreboard and coverage state programs remain
   bounded default correctness candidates because their packed state is below
   the evaluator's closed memory envelope.

## Consequences

- Every checking-state level now has one selected accepted-or-earliest-cap
  outcome before generator code begins.
- The two one-million levels have executable semantic proofs without a
  million-operation plan or a million-record JSON trace.
- The cross-language contradiction is resolved in favor of the older shipped
  source/execution contract and current implementation, with no product change.
- Coverpoint and random route boundaries remain honest evidence of earlier caps;
  they are not rewritten as supported capacity.
- No backend, runtime, support, performance, whole-product capacity, or public
  API claim changes.

## Containment

This decision is one bounded rationale record. Its matching Knowledge Map card
is a bounded canonical fact, and the mdBook remains the user-facing maintained
reference. Implementation remains separately owned by `.17.2.5.2`.
