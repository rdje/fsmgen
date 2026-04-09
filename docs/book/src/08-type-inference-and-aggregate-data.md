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

## Future Pack And Deconstruct Direction

FSMGen may also grow an intent-level way to pack and deconstruct aggregate-like
values in assignments. This is a future direction, not shipped behavior yet.

The shape to keep in mind is:

- an RHS pack form would build one target from several static-width
  expressions
- an LHS deconstruct form would split one RHS into several legal static
  lvalues
- authored left-to-right order should map high-to-low in the packed value
- total widths and element type compatibility must be checked before HDL
  generation
- overlapping or duplicated LHS ranges should fail unless a future semantic
  pass defines deliberate merge or priority behavior

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
