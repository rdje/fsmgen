# 0057 — VIAL scale byte candidates and construction envelopes are derived and bounded

- Date: 2026-08-10
- Type: verification architecture/scalability
- Status: accepted
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md)
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.1`

## Context

Decision `0055` selects exact per-source and combined-source byte caps and says
every primary axis has reference, gate-candidate, qualification-candidate,
limit, and over-limit levels. Its semantic tables do not assign candidate byte
values, and its correct over-limit rule is the first complete valid record
above the boundary rather than arbitrary text padding or necessarily one byte.

The same decision says emitted lines and bytes are measured outputs and must
not be padded. Therefore source-input byte candidates need an exact derivation,
while backend-output candidates must inherit genuine upstream workloads rather
than target an invented emitted size. The shared constructor also needs a
bounded envelope large enough to form exact boundary/over-boundary inputs
without becoming a second product limit or admitting downstream IR forgery.

## Decision

1. Derive source-byte gate candidates as `floor(declared_cap / 16)` and
   qualification candidates as `floor(declared_cap / 4)`. These ratios select
   deterministic correctness workloads only; they are neither performance
   budgets nor capacity/support claims.
2. The 1,048,576-byte per-source axis therefore uses 65,536-byte gate and
   262,144-byte qualification candidates. The 16,777,216-byte combined-source
   axis uses 1,048,576-byte gate and 4,194,304-byte qualification candidates.
3. `limit_v1` targets the exact declared byte cap using valid, referenced
   source records. `over_limit_v1` appends the first complete valid record that
   makes the input exceed the cap; its minimum is cap plus one, but record
   integrity is authoritative over an exact plus-one byte total.
4. Bound the shared source-only construction envelope at 1,114,112 bytes per
   input and 17,825,792 combined bytes. The individual 64-KiB and combined
   1-MiB margins admit one deterministic bounded-width excess record. They are
   constructor safety bounds, not parser limits.
5. The shared boundary accepts only VIAL source, HIAL source, and replay-
   manifest bytes. It may identify and stage those inputs but may not accept or
   synthesize SemanticIR, bridge manifests, execution plans, backend artifacts,
   traces, or results. Later family leaves must obtain those from canonical
   producers.
6. Backend emission gate/qualification candidates inherit the corresponding
   proved upstream workload. Generated lines/bytes remain measured outputs.
   Limit/over-limit evidence must use genuine generated graphs and report an
   earlier authoritative cap when it dominates.
7. Version 1 uses fixed seed `1701`, the shipped
   `sha256_counter_rejection_v1` payload algorithm, eight-digit stable ordinals,
   canonical JSON identity over the complete specification plus path-sorted
   input digests, and repository-derived `.artifacts/tmp/vial-scale/` staging
   removed on success and failure.
8. Logical tool selectors are `verilator_5_046`,
   `ghdl_6_0_0_llvm_jit`, and
   `osvvm_2026_05_ghdl_6_0_0_llvm_jit`. They identify already-qualified
   profiles without embedding discovery paths or claiming a measured scale.

## Consequences

- Every selected source-byte level is reproducible without hiding an arbitrary
  magic number in implementation.
- A valid whole record, not filler or an exact plus-one byte fiction, owns
  over-limit construction.
- Backend bytes stay honest outputs of semantic workloads.
- The constructor is bounded, repository-local, path-independent in durable
  identity, and unable to forge later-stage evidence.
- Architecture-scale capacity, whole-product `big`/`really_big`, multi-unit or
  multi-domain, mixed-language, native-UVM runtime, full-language, synthesis,
  and general backend-parity claims remain absent.
