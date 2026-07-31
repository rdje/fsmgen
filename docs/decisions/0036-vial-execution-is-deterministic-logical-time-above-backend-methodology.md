# 0036 — VIAL execution is deterministic logical time above backend methodology

- Date: 2026-07-31
- Type: verification language and execution architecture
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6`
- Preserves: `0008`, `0018`, `0022`, `0032`, `0033`, `0034`, `0035`

## Context

The shipped `VIALSemanticIR` contains closed typed verification intent but
deliberately leaves HIAL references unresolved. The shipped
`HIALVIALBridgeManifest` supplies exact review-routed DUT facts but deliberately
does not bind or execute VIAL. A stable execution boundary is now required
before any SystemVerilog, UVM, or VHDL verification backend can be selected.

Exposing target scheduling regions, UVM phases or objections, factories,
callbacks, VHDL delta-cycle folklore, host threads, or host-language callback
objects at that boundary would invert decision `0034`. Those mechanisms are
compiler implementation choices. VIAL authors need their semantic outcomes:
ordered drive and observation, lifecycle, notification/interception, bounded
concurrency, cancellation, replay, checking, and finalization.

Randomness and parity also cannot depend on backend callback order. The first
source gives every choice a stable decision identity and scenario scope, so the
compiler can resolve it once into the plan rather than asking each target
runtime to reproduce an incidental PRNG call sequence.

The existing FSMGen Perl typed-extension mechanism is not a suitable VIAL
native boundary. It explicitly exposes blessed Perl objects, live pipeline
objects, and mutable result hashes and is recorded as non-portable by
`docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md`.

## Decision

Select private immutable `VIALExecutionIR` schema
`fsmgen.vial_execution_ir.v1` with initial profile
`core_directed_single_clock_execution_v1`. It is a target-neutral operational
graph produced by exact binding of one `VIALSemanticIR` fixture to one
`HIALVIALBridgeManifest`; no verification backend consumes SemanticIR or the
bridge independently.

Select logical time as `(domain, cycle, phase, ordinal)` with ordered phases
`drive`, `sample`, `react`, and `check`. Stable operation ranks, fiber ranks,
and local emission indices resolve same-time ties. Host thread order, simulator
regions, delta cycles, callbacks, and UVM methodology scheduling have no
semantic authority. Backends may use those mechanisms only when they preserve
the selected logical ordering.

Select a capability ledger that classifies every requirement as satisfied by
the target-neutral execution profile or required from a later backend profile.
Unknown, contradictory, or semantically unsatisfied capabilities fail binding.
A target-neutral plan may retain known backend requirements, such as an
equivalent verification-probe adapter, but a backend must satisfy them before
emitting any target artifact.

Resolve version-1 random choices during elaboration with the exact keyed
`sha256_counter_rejection_v1` algorithm. One scenario-scoped occurrence is
independent of traversal, fiber scheduling, host PRNG state, and backend call
order. `VIALExecutionIR` stores the chosen normalized value and whether it was
generated or replayed. Backends consume the value; they do not rerandomize it.

Select typed VIAL native-extension manifests as external, repository-relative,
content-addressed implementations of declared VIAL semantic intent. They carry
closed logical lifecycle hooks, typed inputs/outputs, declared deterministic
effects, capability/profile requirements, and required/paired/fallback policy.
They contain no callback/code reference or private IR object. Hook names are
VIAL compiler seams, not UVM phase names or VHDL process names. The first
execution profile contains no native extension because the shipped source
profile declares none.

Select sanitized `fsmgen.vial_plan.v1`, normalized
`fsmgen.verification_result_manifest.v1`, and
`fsmgen.vial_parity_report.v1` data contracts. Result parity compares a
canonical portable projection of logical events, values, transactions,
checks, model/scoreboard/coverage/fault outcomes, fibers, decisions, completion,
and exclusions. Generated source, simulator timestamps, waveforms, host timing,
target paths, and tool chatter are evidence, not the semantic oracle.

SystemVerilog/UVM/VHDL remain backend target languages in the same
architectural sense that assembly is a compiler target for C/C++ or Rust.
VIAL expresses lifecycle and verification intent; a UVM backend may choose
phases, objections, factories, config DB, TLM, events/callbacks, and other
methodology machinery without exposing them as authored VIAL concepts.

## Consequences

- `.7` owns the private binder/elaborator, immutable ExecutionIR, sanitized
  plan projection, deterministic random/replay implementation, and contract
  oracles without emitting a target-language artifact.
- `.8` still owns public CLI/API/file placement, artifact discovery, and
  compatibility. This decision selects data shapes, not public files.
- Each backend receives one already bound operation graph and fixed decision
  values, then must prove its scheduling implementation preserves logical-time
  semantics before runtime support or parity can be claimed.
- Probe/native requirements remain explicit. They cannot be silently dropped
  to make a target appear portable.
- Native semantic-family growth remains owned by `.19`; this decision selects
  the safe execution carrier, not a one-to-one SV/UVM/VHDL feature catalog.
- Exact records, algorithms, phase/action semantics, diagnostics, resource
  caps, AHB binding oracle, non-claims, and rollback are canonical in
  `docs/VIAL_EXECUTION_IR_V1_CONTRACT.md`.

## Implementation Review

Audit `.7.1` found that the checked fixture cannot satisfy this decision's
exact transaction-field type-equivalence wording. VIAL preserves an enum,
Boolean, and unsigned numeric type where the HIAL bridge correctly preserves
their hardware carriers as four-state logic. The evidence and alternatives are
canonical in `docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md`.

The director approved the closed proof-carrying directional representation
rule. Decision `0037` and completed `.7.2` now refine this decision without
weakening its target-neutral type safety: semantic types remain VIAL-owned,
carrier types remain HIAL-owned, drive relations are closed and directional,
and inverse X/Z collapse remains forbidden. `.7.3` owns implementation after
separate clean activation; no binder exists in the selection slice.
