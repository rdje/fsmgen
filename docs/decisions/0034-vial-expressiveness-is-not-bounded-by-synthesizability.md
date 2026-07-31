# 0034 — VIAL expressiveness is not bounded by synthesizability

- Date: 2026-07-31
- Type: language and verification architecture
- Status: accepted by director clarification during `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3`
- Refines: `0032`, `0033`

## Context

HIAL describes hardware intent and is deliberately constrained by what can be
lowered into synthesizable HDL. VIAL describes verification intent. Treating
VIAL's first portable profile as the whole language would incorrectly import
HIAL's synthesis constraint and permanently lose native SystemVerilog/UVM or
VHDL verification semantics.

The first VIAL profile is intentionally small, but future native verification
needs first-class methodology semantics. In particular, a UVM event is not
merely an SV event, and `uvm_event_callback` behavior includes registration,
ordering, filtering, lifecycle, reentrancy/cancellation, and observable effects
that cannot be preserved by flattening it into the portable event subset.

The language must remain intent-revealing rather than recreate target syntax.
It also needs both terse authored forms and an explicit normal form without
creating two meanings.

## Decision

Adopt **“full power underneath, simpler intent above”** as VIAL's language-
design rule. VIAL covers the expressive verification use cases enabled by its
qualified targets; it does not expose every target-language or methodology
concept.

Here, abstraction means simplification. An author can master and use VIAL
without prior knowledge of SystemVerilog, UVM, or VHDL. Target-language and
methodology expertise belongs in the compiler and qualified backend. Those
backends must produce efficient, readable target artifacts without making
target plumbing, terminology, or execution folklore prerequisites for writing
correct VIAL. A construct that merely moves such detail upward under a new
spelling has failed the abstraction rule.

Conceptually, SV/UVM and VHDL are backend target languages for VIAL in roughly
the way assembly languages are compiler targets for C/C++ or Rust. Generated
artifacts remain readable and source-mapped for diagnosis, interoperability,
and qualified-tool use, but VIAL semantics are never defined by one target's
idioms.

VIAL is not synthesis-bounded. Its expressive ceiling is typed verification
intent plus the capabilities of an explicitly qualified backend/methodology
profile. `core_directed_single_clock_v1` and the portable profiles are initial
subsets, not the definition or permanent ceiling of VIAL.

Native semantic families may cover the full verification use cases enabled by
qualified SystemVerilog/UVM or VHDL, while keeping target mechanisms private.
VIAL expresses notification/interception, lifecycle, stimulus orchestration,
producer/observer communication, implementation selection/substitution,
configuration, register intent, constrained decisions, coverage, properties,
and timed interface interaction. The compiler may realize those semantics with
UVM events/callbacks, phases/objections, sequences, TLM, factories/config DB,
RAL, randomization/coverage/assertion facilities, or virtual interfaces and
clocking blocks. Those target concepts do not automatically become VIAL
concepts. VIAL records stable intent identities, ordering, capability,
source-map, diagnostic, and result semantics rather than exposing anonymous
raw target-language blocks.

Admit a native semantic family only when it exposes, composes, or compresses a
verification intent. A one-to-one catalog of renamed SV/UVM/VHDL classes,
methods, statements, or syntax is explicitly rejected. For example, VIAL event
callbacks model interception, filtering, ordering, lifecycle, cancellation,
transformation, and observation intent; the UVM backend chooses the required
`uvm_event_callback` machinery. Likewise, implementation substitution is VIAL
intent while UVM factory registration and overrides remain compiler details.
The target mechanism is a mapping, not VIAL's semantic definition.

UVM phases and objections are also backend-private. VIAL expresses lifecycle
intent: construction/configuration/readiness dependencies, stimulus start,
background-service lifetime, completion and drain conditions, shutdown,
cleanup/finalization ordering, deadlines, and failure policy. The UVM compiler
selects phases and emits raise/drop-objection or phase-transition plumbing. An
authored VIAL surface does not expose `run_phase`, `raise_objection`,
`drop_objection`, or `phase.jump()` merely because the backend uses them.

VIAL will support a terse surface and a verbose normal surface that lower to
the same typed semantic records. Tooling must be able to expose the normal
form for review and diagnostics. Terseness may remove ceremony, never semantic
facts.

Portable features map across qualified backends. Native features use explicit
profile capabilities. A VHDL backend either provides a selected equivalent
semantic mapping or rejects the required capability before output; it may not
silently weaken UVM-native meaning.

## Consequences

- The bounded `.3` parser/SemanticIR implementation remains the first profile
  and is not widened by this decision.
- Execution/native-extension contracts must support typed methodology-owned
  lifecycles and capability negotiation without turning the portable core into
  the global language ceiling.
- Public syntax/tooling contracts must select terse and normal projections of
  one semantic model and demonstrate that neither requires SV/UVM/VHDL
  knowledge from the author.
- The native UVM contract must explicitly map VIAL notification/interception
  semantics through `uvm_event`/`uvm_event_callback`, keep factories and similar
  methodology plumbing backend-private, and establish a staged taxonomy of
  verification intents rather than target feature wrappers.
- VHDL and mixed-language profiles retain exact capability qualification; no
  cross-backend equivalence is inferred.
- Backend contracts own efficiency/readability criteria for generated target
  artifacts; simplification of the source surface may not excuse inefficient
  lowering or opaque output.
- Proposed architecture leaf `.19` owns the detailed post-first-backend
  expressive-frontier taxonomy and task-tree decomposition before the
  architecture can close.
