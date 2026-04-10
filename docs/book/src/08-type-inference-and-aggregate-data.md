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
- bounded aggregate constant values
- packed aggregate type aliases through `(list ...)` and `(record ...)`
- declared-type preservation through the live pipeline
- aggregate-aware compatibility checks on the current live paths

What is not fully shipped yet:

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
(?toplink:wiring
  /in_frame.tag/tag_out/
  /in_frame.payload[1]/sink.payload_mid/
  /producer.OUT_FRAME.flag/sink.enable/
)
```

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
  (OUT.payload = TAIL)
)
```

Here `TAIL` must match the declared type of `OUT.payload`, not merely the
packed width of `OUT` or the packed width of `payload`. Compatible aggregate
leaf writes are accepted; width-equal but list-vs-record or otherwise
shape-incompatible writes fail before HDL emission.

This is still deliberate and bounded. Broader inference-first aggregate growth
without explicit declared anchors remains future work; the backend should
never pretend a richer type surface is stable before it really is.

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
  directly; if an aligned operand is typed aggregate data, that operand's
  type-shape contract is preserved for the pre-generation validator

The important boundary is the same one used elsewhere in FSMGen: the frontend
should normalize and validate the meaning first, then the backend should emit
the already-upright AST/IR.

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
