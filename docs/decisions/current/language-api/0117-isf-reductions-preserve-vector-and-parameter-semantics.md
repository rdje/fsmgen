---
id: isf-reduction-and-group-contract
title: ISF reductions preserve vector and parameter semantics
answers:
  - "what syntax and bit order are selected for SPECFORGE byte-group reductions?"
  - "what must be preserved before parameterized reductions can ship?"
  - "what reduction width groundwork is implemented?"
  - "how are declared reduction records prepared without source admission?"
  - "why do reductions preserve delegated storage sample declarations?"
  - "why did admitted reductions fail when transaction formals were present?"
date: 2026-10-22
status: current
tags: [isf, reductions, specforge, parameters]
evidence: docs/audits/specforge-reduction-intake-20261021/packet.json; docs/audits/unary-reduction-source-integration-20261022.json.gz; docs/tasks/ISF-REDUCTION-DELIVERY.md; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm
---
# 0117 — ISF reductions preserve vector and parameter semantics

- Type: language and lowering contract
- Status: selected; unary source integration implemented; qualification continues
- Owner: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.92.1`

## Context

SPECFORGE request `.12` requires scalar reductions and grouped reductions over
parameter-dependent widths. Its retained source and current refusals are in
`docs/audits/specforge-reduction-intake-20261021/`. The illustrative
`(! (^ DATA))` means inversion of a whole-vector parity bit; it cannot mean a
vector of independently inverted byte parities.

At intake the shared expression builder required multiple operands for `^`,
`&` and `|`. ISF preserves expressions in scheduled IAL0 text, but emitting a
numeric default width loses its dependency. At intake, unary AST nodes and their
width consumers also needed explicit reduction result semantics. Passing a
source check cannot establish HDL behavior or safe external parameter overrides.

## Decision

### Unary reductions

Select `(^ X)`, `(& X)` and `(| X)`: reduce every bit of X to an unsigned
single-bit result. X is a declared positive-width packed scalar signal, its
supported scalar field, a legal static slice, or a bit selection. A bit reduces
to itself. Reuse existing declared types, path bounds and lexical/domain rules.
Reject aggregate roots, strings, unresolved/unknown signals, parameter values,
unsized numbers and unsupported expression operands with the operand and
source context identified. Do not infer a missing declaration from a reduction.
The existing normalized aliases `xor`, `and`, `or` have the same arity-dependent
meaning. Multiple operands retain their current behavior and association;
negated multi-operand forms and logical `!` retain their existing semantics.

### Grouped reductions

Select `(reduce-groups OP X N)`, with literal OP one of `^`, `&`, `|` and N a
positive decimal integer literal. The packed scalar operand contract is the
same as for unary reduction. For operand width W, the result width is
`ceil(W/N)`. Result bit i reduces the operand positions starting at `N*i`,
through `min(W-1, N*i+N-1)`. Positions are relative to X's packed value, so a
slice starts at its own least significant bit. The final group may be short;
no padding bit changes the result. N greater than W produces a single group.
Invalid operators, nonliteral/nonpositive N and invalid operands fail closed.

Assignment targets must have exactly the grouped result width under strict
checking. Diagnostics name the target width and derived group count. Nested
uses retain the grouped result width; a logical `!` over that vector still
produces a single Boolean, never elementwise odd parity.

Select optional `(~ X)` as width-preserving bitwise inversion, independently
qualified after required unary semantics. It may invert a grouped result.
Without it, required grouped reduction remains usable; optional inversion must
not block required delivery. No reinterpretation of `!` is permitted.

### Parameters and lowering

Preserve authored width dependencies separately from resolved defaults through
ISF parsing, LoweringIR, IAL0, semantic metadata and HDL. Never reconstruct a
dependency from equal numeric widths. Coordinate generic-port-width ownership
`.33.3` and derived-width ownership `.32.3`; do not create a second evaluator.
An external HDL override must resize the operand, result, associated registers,
intermediates, constants and group loop together. Independent DATA_WIDTH and
DATA_BYTES parameters remain legal only when their values satisfy the group
count relation. Reject invalid source/use-site settings; emit supported
elaboration-time guards for externally overridden relationships. Unsupported
backend/profile combinations fail closed before claiming a valid artifact.

Use canonical IAL0 expressions and typed AST semantics, rather than generated
HDL text replacement or a default-width unroll. Group emission must operate on
the elaborated width and preserve the short tail. Actual default/override HDL
behavior and width declarations require independent qualification.

### Public reports and supported profiles

Add a detached `reductions` inventory to successful ISF schedule reports and
`source.reductions` to successful check/semantic reports when reductions occur.
Entries name source owner/context, `kind` (`unary` or `grouped`), `operator`,
authored `operand`, resolved `operand_width` and `result_width`; grouped entries
also name `group_size` and `group_count`. Preserve a declared width dependency
as `operand_width_source` where applicable. These resolved numbers describe
the selected parameter environment, not every possible external instantiation.
Do not leak parser/AST/private IR objects or invent entries in failed or
unrelated source reports. API, real newline MCP and capability contracts must
agree with native reports. Normalized expression reports retain the actual
operator and result width.

Qualify each existing HDL backend/profile independently. SystemVerilog is the
first delivery target; other profiles retain an explicit refusal until their
expression and parameter contracts are verified. A parser success, generated
carrier, lint result or sibling emitter option is not runtime qualification.

### Delivery order and evidence

`docs/tasks/ISF-REDUCTION-DELIVERY.md` owns bounded implementation slices under
SEM `.92`. Deliver unary semantics independently. Then preserve generic widths,
qualify overrides and legality, and implement grouped reductions. Required
SPECFORGE delivery stays open until R1–R3 all qualify. Optional inversion has
its own acceptance boundary. Keep corpus, public discovery, book, feedback and
roadmap intent aligned in each slice.

Re-derivation uses retained exact caller inputs and native check/schedule/
semantic/carrier products. Falsification uses independently computed scalar
truth tables, group order/short-tail/width mismatch controls, actual HDL
parameter overrides and unchanged binary controls. Durability is tracked
sources, corpus/tests, decision, task evidence and per-slice Git commits.
Runtime and implementation evidence are missing at contract selection.
Publication additionally requires the existing full-CI and exact-SHA hosted
qualification; SPECFORGE separately owns pin/bundle regeneration and integration.

## Width prerequisite

`ISF-REDUCTION-DELIVERY.1.1` prepares scalar reduction width inference across
Core/runtime/substituted AST consumers, distinct named intermediates and
operand-preserving context propagation. The corrected regression fails against
exact predecessor modules and passes against the repair, alongside existing
expression/backend-text controls. Its complete dated audit is
`docs/audits/unary-reduction-width-foundation-20261021.json`.

Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2074-unary-reduction-width-foundation.t`.
That prerequisite retained source refusal; the integration below opens declared
unary forms. Full source/profile and HDL behavior qualification remain successors.

## Declared-expression record prerequisite

`ISF-REDUCTION-DELIVERY.1.2.1` prepares detached unary records from selected
expression payloads and existing declaration/path/sample facts. Expression
preorder preserves separate occurrences and canonicalizes the bitwise aliases.
Source clauses and assignment pairs are not expression payloads: their heads
can be signal names. The integrating caller must select contexts and bind
owner/scope to source. Structural snapshots alone do not attest provenance.
Lost authored width dependencies remain omitted rather than inferred.

Real parsed caller rules, scalar paths, local/sample and drive scopes plus
hostile operand/schema and mutation controls qualify the private producer.
The first draft admitted an invalid owner through a dropped regex predicate;
scalar predicates and exact helper arity apply decision 0113. Detaching before
numeric reads follows 0114. Complete draft, diagnosis and checks remain in
`docs/audits/reduction-record-preparation-20261022.json`.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2075-isf-reduction-record-preparation.t`.
No source, public-report or runtime admission is claimed by this preparation.

## Unary source integration

`ISF-REDUCTION-DELIVERY.1.2.2` connects explicit declaration/path validation,
canonical IAL0 unary parsing and detached optional schedule/check/semantic
records. Source selection visits expression positions, preserving owner/context
and expression order; an assignment target named `xor` is not an operator.
Static values mask same-named wires consistently with shared frontend resolution.
A scalar sample retains its explicit private declaration and known type/width
before its reduction is read by the canonical frontend. No inferred declaration
or width fallback admits an unknown operand. The reduction consumer uses the
existing port-only sample plan and leaves its unresolved/delegated samples
masked. Whole packed-storage captures and their sample chains retain the
legacy inference owner instead of receiving scalar declarations merely because
an unrelated reduction occurs. Record-port whole samples remain refused.
Reverify with `scripts/run_with_ram_guard.sh -- prove -Iperl t/2077-isf-reduction-delegated-samples.t`.

Formal operand rewriting must share canonical normalization and unary reduction
classification. Its former family-only arity check rejected an already admitted
reduction whenever direct formals activated source rewriting. T2078 exercises
all canonical/alias spellings, nested use, distinct physical formal widths and
authored source inventories through actual carriers and native/API/newline
products. The detached formal report view re-derives reduction records from its
original preparation actor: LoweringIR must retain physical operand identities
for execution, while source reports retain authored spellings. The initial
arity-only repair exposed this second omission rather than qualifying the
generated spelling as authored provenance. It preserves unrelated arity and
role controls. Reverify with
`scripts/run_with_ram_guard.sh -- prove -Iperl t/2078-isf-reduction-formal-arity.t`.
The independent existing mixed-record/private-formal write refusal is owned by
`.8`; this arity repair does not broaden source write roles.

Unary AST, canonical serializers and the executed enable-graph capture renderer
group both the operand and expression. Direct VHDL recognizes exactly one
balanced operand wrapper through its existing bounded fold path. The real
negation predicate must also classify Core/runtime/substituted reductions as
one bit, consistently with exact width inference; otherwise it emits a redundant
compound NOR that the VHDL converter refuses. Source negation keeps its Boolean
meaning. Other unary behavior stays unchanged; the independent private scalar
complement classifier gap is P2-owned under `.7.1` after unary delivery. Direct VHDL still refuses range slices; this
integration does not qualify external VHDL execution under decision 0023.
`isf/unary_reductions.isf` is the supported source fixture; T2076 binds literal
source records to native/API/newline products and actual generated IAL0.
Broader source/profile/corpus coverage and actual HDL runtime remain `.1.2.3`
through `.1.4`; generic widths/groups and publication remain required. This
source milestone does not close R1–R3 or unblock SPECFORGE `.46.c`.
