# Language and Data Backlog

## Language Ergonomics

### Source-Facing FSMGEN HIR

Status: private architecture boundary validated across IAL2 and IAL1; frontier complete.

Goal: give future high-level language frontends and builder APIs one checked
FSMGEN-native semantic target above IAL2 and IAL1. The intended architecture is
`high-level frontend -> FSMGEN HIR -> validation/canonicalization -> IAL2 or
IAL1 -> existing lowering`.

Current boundary: `FSMGEN-HIR-ROADMAP-FRONTIER` owns the phase. HIR does not
replace IAL2 or IAL1; it should lower to IAL2 for
protocol/platform intent and to IAL1 for concrete FSM/control logic. Direct
frontend lowering to IAL2 or IAL1 can still be acceptable for one bounded
prototype, but multiple high-level frontends should not each reimplement every
IAL target rule, scheduling rule, width/reset convention, diagnostic rule, and
future IAL evolution.

Selected architecture: the source-facing layer is a distinct private
`FSM::IR::SourceHIR`, not an extension of the existing post-parse
`IntentHIR`. The first repository-internal constrained Perl builder will
construct one protocol-neutral valid-ready object, validate it, render
canonical `.ppif`, and then use the existing PPIF parser and
`IAL2 -> IAL1 -> IAL0` pipeline. The golden output is
`ppif/valid_ready_handshake.ppif`, reproduced byte-for-byte.

This selection does not expose a public builder, CLI mode, raw HIR object, or
report schema. Version 1 is now frozen as one closed immutable valid-ready
object with JSON-Pointer-style provenance, structured private diagnostics,
deterministic canonical PPIF text and source map, and byte equality with the
14-line/428-byte tracked fixture. The private three-package implementation and
focused t1547 proof now ship internally: rendered text re-enters the existing
PPIF parser and produces equal IAL1, IAL0, schedule, and protocol reports.
There is still no public builder, CLI mode, HIR report/manifest/accounting
surface, or direct generator path. The post-prototype audit keeps SourceHIR
private: the working valid-ready path warrants retention, while one test
producer, one schema, and only the IAL2 route do not justify a public contract.
The design leaf selects version 2 as a semantic concrete-control subset:
clock/reset, ordered typed ports, one parameter-to-output named drive, and one
linear trigger/phase/completion transaction. It reproduces the existing
17-line/395-byte `isf/phase_test.isf`, re-enter the shipped ISF adapter and
scheduler, and preserve the one-file 45-line/484-byte IAL0 result. It stores no
raw ISF form, arbitrary expression, or parser AST. The private implementation
now reproduces the exact ISF and IAL0 bytes, re-enters the existing adapter and
scheduler with equal typed actor/schedule results, and adds no public surface.
The two-route audit retains SourceHIR privately: coherent IAL2 and IAL1 proofs
reject retirement and narrowing, while test-only producers and the absence of
a supported language/package, versioning, compatibility, serialization, and
public diagnostics contract reject current-shape promotion. No third
architecture-only route is planned. Public host-language choice, packaging,
projection, versioning, and compatibility remain owned by the separate
proposed builder frontier.

### Inference-First Scalar Authoring

Status: partially shipped; broader inference surfaces remain backlog.

Goal: make scalar declarations optional across the whole language whenever a
safe type and width can be recovered from authored usage.

Current boundary: FSMGen already infers widths from explicit `+size`, scalar
type aliases, positive integer scalar symbols, symbolic scalar `+types`
`(bits WIDTH_SYMBOL)` specs, slices, selectors, guards, and other bounded
evidence. It does not yet promise "never declare scalar types unless you want
to" across every source position.

### Dynamic Divisor Safety Proofs

Status: partially shipped.

Goal: reject or prove safe runtime division/modulo expressions whose divisors
could be zero.

Current boundary: constant-expression domains reject divide/modulo-by-zero
before HDL emission, and direct `.fsm` runtime expressions reject
numeric/exact-width literal-zero divisors before HDL emission. ISF runtime
expression contexts now reject numeric/exact-width literal-zero divisors and
actor-level constants that resolve to zero, plus actor-local scalar parameter
defaults that resolve to zero, plus same-transaction scalar parameter defaults
that resolve to zero, before scheduled `.fsm` emission. Nonzero literal
divisors, nonzero actor-constant divisors, nonzero actor-parameter divisors,
nonzero same-transaction parameter divisors, and dynamic scalar divisors are
emitted unchanged; FSMGen does not yet prove every dynamic divisor nonzero.
Nonzero actor parameters and nonzero transaction parameters remain outside a
full nonzero proof because they are overrideable specialization values, not
fixed actor constants.

## Aggregate Types And Data

### Portable Synthesizable Type Core

Status: partially shipped; broader portable type core remains backlog.

Goal: define one frontend type model that stays semantic and portable across
SystemVerilog and future VHDL instead of exposing backend-specific spelling as
the source-language contract.

Current boundary: the shipped `+types` surface covers scalar aliases for
`bit`, `(bits N)`, positive symbolic widths, signed variants, explicit
`two_state` / `four_state` intent, local/imported aliases, and packed
`list` / `record` aggregate aliases. Direct roots and composition tops preserve
those exact contracts through symbol contracts, `Intent HIR`, `module_info`,
`Structural RTL IR`, realized child interfaces, structural connection
expressions, and SystemVerilog declaration lowering.

Direct roots support typed aggregate member/list-item reads and partial
aggregate LHS writes when the base signal has a declared aggregate type.
Composition supports typed aggregate top-port and generated-child output
member/list-item source paths, whole aggregate actuals, typed structural
bindings, and bounded aggregate-root inference when a declared or safely
inferred aggregate root already exists.

Remaining backlog: enum-as-type unification with the existing `+enums`
family, fixed-size arrays, arrays of records, broad inference-first scalar
declarations, aggregate member/index autogrowth from partial use, arbitrary
subaggregate runtime operators, VHDL record/array lowering, backend-neutral
signedness/state-model policy across every inferred site, and richer public
type/export APIs remain deferred until one exact task-tree-owned contract is
selected.

### Automatic Aggregate Growth From Usage

Status: partially shipped; broader inference surfaces remain backlog.

Goal: infer aggregate record/list shapes from member/index usage when no
explicit aggregate type anchor is present.

Current boundary: aggregate aliases, aggregate constants, declared aggregate
types, direct-root aggregate member/list expressions, partial aggregate LHS
writes, direct whole-signal target contract inference from whole aggregate
constant roots, and list-only direct RHS concat target autogrowth are
supported on the current SystemVerilog path. Broad automatic aggregate type
growth from arbitrary usage is not fully shipped. Member/index-root
autogrowth from partial use remains backlog because it does not yet provide a
complete, conflict-free hardware shape proof.

### Backend-Owned Struct/Record Default Lowering

Status: partially shipped; broader default-lowering policy remains backlog.

Goal: make backend-owned structured `struct`/record emission the default
lowering where it is portable and synthesizable.

Current boundary: generated-module and composition-top packed typedef emission
exists for aggregate aliases and other exact aggregate contracts on the current
SystemVerilog path. The shipped Verilog-family declaration renderers preserve
named aggregate contracts as backend-owned packed typedefs on direct module
ports, direct internal/helper declarations, structural composition ports and
nets, projected child aggregate carriers, and bounded inferred direct targets.

Structured record lowering is not the default for every aggregate-like value.
FSMGen does not invent structs from partial member/index use, width-only
matches, anonymous record guesses, or target families without a proven
synthesizable lowering. VHDL aggregate lowering and ISF aggregate aliases on
interface ports, transaction ports, and banks remain backlog.

### Richer Aggregate Operators

Status: partially shipped; broader operators remain backlog.

Goal: widen aggregate operators beyond the shipped matching-shape leafwise
numeric and bitwise families.

Current boundary: semantic parameter/generic aggregate values support matching
list/record aggregate shapes with leafwise `+`, `-`, `*`, `/`, `%`, `&`, `|`,
`^` plus word aliases before HDL lowering. They also support unary bitwise
aggregate complement through `(~ VALUE)` and `(not VALUE)`, and binary
aggregate comparison through `(== A B)` and `(!= A B)` for matching aggregate
shapes. Comparison folds to a scalar exact-width `1'b1` or `1'b0`.

Additional aggregate operators remain deferred until each operator has a
defined type/shape/result contract and validation path. Runtime direct `.fsm`
aggregate-to-aggregate operators, ISF runtime subaggregate operands, aggregate
paths in expression-operator position, VHDL aggregate lowering, mixed
scalar/aggregate operators, and mismatched aggregate shapes remain deferred.
The R11 parameter/generic frontier audit did not select another aggregate
operator widening; future work must first name one exact type, shape, result,
and lowering rule.

### VHDL Aggregate Lowering

Status: backlog, behind future VHDL aggregate-lowering work.

Goal: lower aggregate types and values into portable VHDL record/array forms
for the subset that can be validated as synthesizable.

Current boundary: direct single-FSM VHDL generation has a scaffold subset for
scalar/vector ports, basic enables, reset processes, concat assignments, and
bounded aggregate-output packed-vector lowering. Full aggregate VHDL
record/array lowering is still not shipped. The maintained direct aggregate
output fixtures lower their generated packed struct outputs as VHDL
`std_logic_vector` ports while preserving flattened mux assignments.
Declared aggregate structural VHDL ports/nets/types in composition tops are
locked fail-closed by `BACKEND-API-VALIDATION-FRONTIER.101.1` before any
record/array declaration emission.
The first bounded composition VHDL structural top is also shipped for the C3
external-RTL literal/concat fixture in
`t/corpus/composition_intent_integer_literals.fsm`. The bounded C1
standalone-DT passthrough composition VHDL top is shipped for
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, emitting the child VHDL
entity and a top-level `entity work.standalone_route_src` port map. Neither
composition leaf provides VHDL record/array aggregate lowering.

### Public Type And Export Surfaces

Status: backlog.

Goal: expose richer type/export information to embedders without leaking
unstable internal objects.

Current boundary: bounded semantic and manifest surfaces exist, but richer
public type/export APIs remain under the broader public embedding/API lane.
