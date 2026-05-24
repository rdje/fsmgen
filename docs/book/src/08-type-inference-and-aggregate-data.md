# Type Inference and Aggregate Data

This chapter explains the long-term typing philosophy and the current shipped
boundary.

## The Direction

FSMGen is aiming for an authoring surface that feels closer to a dynamic
language than to handwritten HDL declarations.

The principle is:

- infer whenever one safe answer exists
- do the hard semantic work inside the engine
- fail explicitly when meaning is ambiguous

That applies to both scalars and aggregates.

## Current Shipped Reality

The full inference-first vision is not complete yet.

What is shipped today:

- widths from explicit `+size`
- widths from scalar type aliases
- widths from positive integer scalar symbols
- symbolic scalar type widths such as `(type byte_t (bits BYTE_W))`
- bounded aggregate constant values
- packed aggregate type aliases through `(list ...)` and `(record ...)`
- declared-type preservation through the live pipeline
- aggregate-aware compatibility checks on the current live paths

The consolidated backlog for the following not-fully-shipped items is
[Feature Backlog](14-feature-backlog.md). The type/aggregate highlights are:

- “never declare scalar types unless you want to” across the whole language
- broad automatic aggregate type growth from arbitrary usage
- backend-owned struct/record emission as the default lowering

## Mixed Integer Formats

The user-facing direction is intentionally permissive when one meaning is clear.

Examples that the engine should normalize safely:

- binary, decimal, octal, and hex spellings
- signed and unsigned numeric forms
- underscore-separated readability spellings

The author should not have to rewrite a design just because one value is
written as hex and another as decimal.

## Aggregate Data

The current aggregate mental model is:

- `list` means ordered packed elements
- `record` means ordered named fields

Current whole-aggregate lowering works when every leaf still resolves to one
scalar literal.

Record packing currently follows authored member order.

## Packed Lowering Rule

Today, the live SV path preserves declared aggregate aliases into backend-owned
packed typedefs on the shipped direct generated-module and composition-top
surfaces.

That means:

- type identity is preserved semantically
- compatibility checks can use the aggregate shape
- emitted SystemVerilog declarations can keep record fields and deterministic
  list fields visible through packed structs

The backend-owned typedef path is intentionally contract-backed. It is used
when the signal, port, net, or helper declaration carries both a stable
aggregate type name and an exact list/record type spec. That currently covers
direct generated-module ports, direct internal/helper declarations, structural
composition ports and nets, projected child aggregate carriers, and bounded
inferred direct targets that have already grown a complete aggregate contract.

Typed aggregate direct-root expressions now also preserve declared member and
list-item access when the base signal has a known aggregate type:

```lisp
(idle
  (OUT_TAG = IN_FRAME.tag)
  (OUT_PAYLOAD_MID = IN_FRAME.payload[1])
)
```

The authored list index stays `[1]` in `.fsm`, while the current SV lowering
uses the generated packed-struct field, for example
`IN_FRAME.payload.item_1`.

The same bounded member/item idea is also shipped on the source side of
composition links when the base endpoint preserves a declared aggregate type:

```lisp
(?wiring:wiring
  (in_frame.tag tag_out)
  (in_frame.payload[1] sink.payload_mid)
  (producer.OUT_FRAME.flag sink.enable)
)
```

Declared aggregate top-port paths also participate in bounded top-port
inference. For example, in a source concat such as:

```lisp
(?wiring:wiring
  ((cat in_frame.tag payload) sink.data_in)
)
```

`in_frame.tag` contributes the declared leaf width when `in_frame` already has
a declared aggregate type or has been inferred from another whole-root link to
a typed child input in the same `?wiring` block. It may also use an unlinked
same-name child input when that child input carries one uniform record/list
declared-type contract. With that root contract available, `payload` can be
inferred from the remaining target width. This is still not broad aggregate
autovivification: if `in_frame` is not declared or previously inferred as one
aggregate contract, FSMGen asks for that root contract explicitly.

For generated-child output paths, FSMGen first binds the whole child output to
one typed carrier and then applies the member/item access to that carrier.

The same leaf facts are preserved in the structured reporting surface:
composition provenance endpoint contexts resolve `in_frame.tag` or
`producer.OUT_FRAME.payload[1]` to the aggregate leaf width/type, not just the
packed width of the whole base endpoint.

Whole aggregate RHS values also participate in the pre-generation type-shape
gate. For whole-signal writes, FSMGen compares the aggregate RHS shape against
the target signal's declared aggregate type. For partial aggregate writes, the
check follows the authored leaf target:

```lisp
(idle
  (= (OUT.payload TAIL))
)
```

Here `TAIL` must match the declared type of `OUT.payload`, not merely the
packed width of `OUT` or the packed width of `payload`. Compatible aggregate
leaf writes are accepted; width-equal but list-vs-record or otherwise
shape-incompatible writes fail before HDL emission.

Direct whole-signal targets can now also grow one aggregate contract from a
whole aggregate constant root when the target has no explicit declaration:

```lisp
(+constants
  (FRAME ((tag const_4b1010) (flag 1)))
  (LANES (const_2b10 const_3b101))
)

(idle
  (= (OUT_FRAME> FRAME))
  (= (OUT_LANES> LANES))
)
```

In this bounded case, `FRAME` already has one canonical record shape and
`LANES` already has one canonical list shape before assignment parsing
finishes. FSMGen records those inferred contracts on the whole targets before
SystemVerilog emission, so the generated module can use packed typedefs for
`OUT_FRAME` and `OUT_LANES` instead of exposing only width vectors.

Explicit target declarations remain authoritative. If `OUT_FRAME` is declared
through `+size` as a scalar width or through an explicit aggregate type alias,
FSMGen keeps that declaration. This slice also does not infer arbitrary
member/index roots, does not infer from child endpoints, and does not treat
packed-width equality alone as aggregate compatibility.

Direct whole-signal targets can also grow a generated list contract from a RHS
concat expression when every operand has exact scalar or aggregate type
evidence:

```lisp
(+size
  (FLAG 1)
  (DATA 2)
  (TAG 4)
)

(idle
  (= (OUT> (concat FLAG DATA)))
  (= (NESTED> (concat (concat FLAG DATA) TAG)))
)
```

Here `OUT` grows a list contract equivalent to `list<bit, bits[2]>`.
`NESTED` grows a nested list contract equivalent to
`list<list<bit, bits[2]>, bits[4]>`. The generated SystemVerilog port uses a
packed typedef for each inferred target instead of a width-only vector.

This concat autogrowth is intentionally list-only. `(concat ...)` provides
operand order, not record member names, so anonymous record inference still
requires a declared record target or a future explicit syntax decision.

This is still deliberate and bounded. It should not be read as Perl-style
autovivification for hardware. Perl can create dynamic data-structure paths as
code runs; FSMGen aggregate growth affects ports, storage, packed layout,
type contracts, and emitted HDL declarations before synthesis. FSMGen
therefore only grows aggregates from complete compile-time shape evidence and
fails closed for partial member/index roots or width-only guesses.

Broader inference-first aggregate growth without explicit declared anchors
remains future work; the backend should never pretend a richer type surface is
stable before it really is. The widening is tracked in
[Feature Backlog](14-feature-backlog.md).

## SystemVerilog And VHDL Intent

The semantic type model should eventually carry facts like:

- width
- signedness
- 2-state vs 4-state
- scalar vs enum vs aggregate role

Then the backend can choose the right carrier:

- SystemVerilog `bit` vs `logic`
- signed vs unsigned vector families
- VHDL vector vs numeric carriers where appropriate

without forcing those backend spellings into `.fsm` source.

## Aggregate Autovivification Direction

The future aggregate direction is intentionally close to autovivification:

- member access should grow record shape
- index access should grow list shape
- nested list/record/list layering should be possible when one safe meaning
  exists

But the guardrail remains:

- if the backend cannot honor the inferred shape honestly, generation must fail
  explicitly

## Current RHS Pack And Bounded LHS Deconstruct

FSMGen now has bounded direct assignment pack and deconstruct forms:

```lisp
(idle
  (OUT = (concat HEADER PAYLOAD))
  (ALIAS_OUT = (cat HEADER PAYLOAD))
  ((concat OUT_HEADER OUT_PAYLOAD) = IN_WORD)
  ((cat REG_HI REG_LO) <- NEXT_WORD)
)
```

These are intent-level expressions, not raw renderer text. RHS pack operands
are ordered left to right and emitted high to low in SystemVerilog, for example
`{HEADER, PAYLOAD}`. LHS deconstruct operands use the same authored order:
the leftmost target receives the high RHS slice and the rightmost target
receives the low RHS slice.

Current guardrails:

- direct RHS pack uses `(concat ...)` or the shorter `(cat ...)` alias
- direct LHS deconstruct uses a `(concat ...)` or `(cat ...)` assignment target
- pack and deconstruct operands must have exact widths from declared signal
  widths, bit/slice or typed aggregate leaf access, or explicitly sized literal
  constants on the RHS pack path
- when direct RHS concat drives a declared aggregate target, FSMGen infers a
  source shape contract before generation: list targets compare against the
  ordered concat operand list, nested concat operands keep nested list shape,
  and record targets map exact top-level concat operands onto record member
  order
- when direct RHS concat drives an undeclared whole-signal target and every
  operand has exact type evidence, FSMGen can grow a generated list contract
  for that target; record autogrowth from concat alone remains out of scope
- deconstruct LHS operands must be static writable lvalues: whole signals,
  static bit/slice references, or typed aggregate leaf references
- total width is checked before HDL generation
- if the RHS pack width does not match the LHS width, generation aborts through
  the pre-generation assignment-width contract instead of silently padding or
  truncating
- if a deconstruct target's total width does not match the RHS width, generation
  aborts before HDL emission
- overlapping or duplicated deconstruct LHS ranges fail before generation
- when the RHS is a whole aggregate constant, a typed aggregate signal, or a
  typed aggregate sub-root, exact nested source fragments keep their own
  aggregate type-shape contract, so splitting `FRAME` or `IN_FRAME` into `tag`
  and `payload` checks a `payload_t` target against the source `payload`
  fragment, not against the whole `frame_t` record
- when the RHS is itself `(concat ...)` or `(cat ...)`, deconstruct fragments
  that line up exactly with whole RHS concat operands keep those operands
  directly; nested RHS concat fragments are handled the same way, aligned
  nested operands keep ordered list shape, and typed record targets can map
  exact aligned operands onto record member order before the pre-generation
  validator runs

The important boundary is the same one used elsewhere in FSMGen: the frontend
should normalize and validate the meaning first, then the backend should emit
the already-upright AST/IR. The shared implementation owner for CoreAST
concat/list/record expression-shape inference is
`FSM::Package::AggregateExpressionTypeSupport`; the direct parser and
EnableGraph capture path both use that owner with their local exact-width
resolver instead of carrying parallel list/record walkers.

## Practical Guidance Today

Today, if you want the strongest current contract:

- use named scalar aliases when a width/sign/state-model anchor matters
- use `record` and `list` aliases for aggregate intent
- use aggregate constants and package-backed shared values to avoid magic
  numbers
- use declared aggregate signal access such as `FRAME.flag` and
  `FRAME.payload[1]` when you want the emitted SV to preserve that typed
  member/item intent

That gives you the best current mix of usability and correctness.
