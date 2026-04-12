# Symbols, Types, and Imports

This chapter covers the declarative surfaces that let you name things instead
of repeating raw numerics everywhere.

The current canonical intent-level families are:

- `+constants`
- `+enums`
- `+types`
- `+import`

Compatibility families such as `+define` and `+params` still exist in the live
tree, but they are not the long-term center of gravity for the language.

## Parameters

Use `+params` for direct-root parameter values when the source is describing a
configuration knob rather than a general shared constant. The direct-root
surface now uses the same bounded parameter/generic value normalization policy
as external RTL interface metadata.

```lisp
(+params
  (WIDTH 0x10)
  (RESET_VALUE 8'hA5)
  (LANES (8'hA5 8'h3C))
  (RESET_PARAM RESET_BYTE)
  (MODE_PARAM mode.BUSY)
  (LANE_PARAM LANES)
  (WIDTH_ALIAS WIDTH)
)
```

Scalar values may use decimal, sized SystemVerilog-style literals, unsized
SystemVerilog-style based literals, or `0x` / `0b` / `0o` prefixes. Bounded
literal list/record payloads are also accepted when they can lower to one packed
literal. That keeps the authoring surface convenient while preserving a concrete
semantic value before generation.

Scalar parameter values may also use bounded operator expressions:

```lisp
(+params
  (WIDTH 16)
  (COUNT_PLUS_ONE (+ WIDTH 1))
  (BYTE_PLUS_ONE (+ BYTES[1] 1))
  (MODE_PLUS_ONE (+ FRAME.meta.mode 1))
  (MASKED (and 8'hF0 8'h3C))
)
```

The current expression operators are `+`, `-`, `*`, `/`, `%`, `&`, `|`, and
`^`, with word aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and
`xor`. Operands must resolve to scalar parameter/generic values. That includes
scalar leaves inside list/record aggregate constants, package aggregate values,
and aggregate parameter defaults, for example `BYTES[1]`, `FRAME.flag`, or
`NESTED.meta.mode`. Whole aggregate roots and aggregate subtrees remain blocked
because aggregates still need a known packed value before generation. Width
inference stays conservative for expression defaults.

Direct-root `+params` values may also reuse resolved semantic symbols:
same-root constants, whole aggregate constant roots, enum members such as
`mode.BUSY`, direct `+define` values, and other same-root direct `+params`.
Parameter-to-parameter references are resolved as one acyclic dependency graph,
so declaration order does not matter when there is one safe answer. Cycles such
as `(P_A P_B)` plus `(P_B P_A)` are rejected before HDL emission instead of
being guessed or left for the backend.

In the current direct-root path, references to `+params` remain named parameter
references in expressions instead of being substituted back to their default
literals. SystemVerilog direct-module generation emits those declarations as a
`#(...)` parameter block:

```systemverilog
module example #(
  parameter WIDTH = 16,
  parameter LANES = 16'b1010010100111100
) (
  input  logic clk
);
```

FSMGen keeps width inference conservative here. Explicitly sized defaults and
packed aggregate defaults can contribute exact width where the semantic checker
requires it, but unsized scalar defaults such as `(WIDTH 16)` remain
width-implicit until the HDL context resolves them. Generated-child parameter
override binding is now a separate instance-side contract that targets these
direct `+params` declarations.

## Constants

Use `+constants` for named scalar values and bounded aggregate values.

Simple scalar example:

```lisp
(+constants
  (RESET_BYTE 8'hA5)
  (IDLE_MASK 8'h03)
)
```

Those names can then be used in direct expressions:

```lisp
(idle
  (OUT = RESET_BYTE)
  (<MODE=IDLE_MASK
    (HIT = 1)
  )
)
```

## Enums

Use `+enums` when you want named members instead of magic numbers.

```lisp
(+enums
  (mode
    (IDLE 0)
    (BUSY 1)
    (DONE 2))
)
```

Then refer to members as `mode.IDLE`, `mode.BUSY`, and so on.

This is especially useful in:

- guard equality conditions
- constant-backed aggregate values
- structural actuals in composition

## Types

The current shipped `+types` slice is intentionally semantic, not backend
spelling.

Current bounded scalar forms include:

- `bit`
- `(bits N)`
- `(signed bit)`
- `(signed (bits N))`
- `(two_state TYPE)`
- `(four_state TYPE)`
- named aliases to other scalar types

Examples:

```lisp
(+types
  (type flag bit)
  (type byte (bits 8))
  (type signed_word (signed (bits 16)))
  (type packed_flag (two_state bit))
  (type safe_bus (four_state (bits 32)))
)
```

The intent is:

- width is semantic
- signedness is semantic
- 2-state vs 4-state is semantic
- the HDL backend chooses the final spelling later

## Packed Aggregate Aliases

The first shipped aggregate type aliases are:

- `(list TYPE TYPE ...)`
- `(record (field TYPE) ...)`

Example:

```lisp
(+types
  (type nibble (bits 4))
  (type header_t (list bit nibble))
  (type frame_t
    (record
      (mode (bits 2))
      (flag bit)))
)
```

The semantic type identity is preserved through the pipeline so compatibility
checks can use more than width alone. On the SystemVerilog path, direct
generated modules and composition tops also preserve that identity into the
emitted declaration surface by synthesizing backend-owned packed typedefs for
declared aggregate aliases instead of flattening them back to raw vectors.

That means SystemVerilog may emit shapes like:

```systemverilog
typedef struct packed {
  logic [3:0] tag;
  logic flag;
  struct packed {
    logic [3:0] item_0;
    logic [3:0] item_1;
  } payload;
} frame_t__fsmgen_t;
```

Record members keep authored field names. List members use deterministic
synthetic names like `item_0`, `item_1`, and so on.

Typed aggregate signals can also be read in direct-root expressions when the
base signal has a declared aggregate type:

```lisp
(+types
  (type pair_t (list bit (bits 4) bit))
  (type frame_t
    (record
      (tag (bits 4))
      (flag bit)
      (payload pair_t)))
)

(+size
  (IN_FRAME frame_t)
  (OUT_TAG 4)
  (OUT_PAYLOAD_MID 4)
)

(idle
  (OUT_TAG = IN_FRAME.tag)
  (OUT_PAYLOAD_MID = IN_FRAME.payload[1])
)
```

The source stays intent-level: record fields use `.field`, and list elements
use `[N]`. On the current SystemVerilog path, the generated list field spelling
then follows the typedef convention, so `IN_FRAME.payload[1]` emits as
`IN_FRAME.payload.item_1`. Partial aggregate LHS writes such as
`OUT_FRAME.tag = IN_FRAME.tag` are also mapped through the typed AST to the
correct packed base-signal range before generation.

## Width Tokens From Types And Scalars

Direct-root `+size` and composition `?ports` widths may now come from:

- raw positive integers
- local scalar type aliases
- imported package-qualified scalar type aliases
- local positive integer scalar symbols
- imported positive integer scalar symbols

Example:

```lisp
(+constants
  (BYTE_W 8)
)

(+types
  (type byte (bits BYTE_W))
)
```

And in composition:

```lisp
(?ports:public_io
  data_in<BYTE_W
  packed_out>byte
)
```

## Imports

Use `+import` to pull semantic package symbols into scope.

```lisp
(+import shared)
```

The imported names stay namespaced:

- `shared.RESET_BYTE`
- `shared.mode.BUSY`
- `shared.frame_t`
- `shared.BYTES[1]`
- `shared.FRAME.flag`

That is intentional. FSMGen packages are semantic imports, not textual include
files.

## Declarative Scope

Within one declaration family, normal non-cyclic references are no longer
order-dependent.

This is valid:

```lisp
(+constants
  (PACKET (HEADER mode.IDLE))
  (HEADER (mode.BUSY RESET_BYTE))
  (RESET_BYTE 8'hA5)
)
```

But explicit cycles still fail:

```lisp
(+constants
  (A B)
  (B A)
)
```

## Current Boundary

What is shipped today:

- named scalar constants
- bounded aggregate constants
- enum families
- scalar type aliases
- packed list and record aliases
- semantic imports from `?pkg`
- declared-type preservation across the live pipeline
- direct generated-module packed typedef emission for aggregate aliases
- composition-top packed typedef emission for aggregate aliases
- direct-root typed aggregate signal member/list-item access in expressions
  and partial aggregate LHS writes on the SystemVerilog path

What is still future work:

- broader inference-first typing so users need fewer explicit anchors
- broader inference-first aggregate member/index typing without explicit
  declared aggregate anchors
- VHDL aggregate-type lowering beyond current scalar/width-safe surfaces
- richer public type/export surfaces for embedders
