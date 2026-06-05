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

## Declaration Shape Contract

These declaration sections are parsed as semantic source forms, not as loose
lists for the backend to guess later. Malformed section shapes fail explicitly.

Current accepted families are:

- `(+size (signal width_or_type) ...)`
- `(+constants (NAME value) ...)`
- `(+define (NAME scalar_value))`
- `(+params (NAME value) ...)`
- `(+enums (enum_name (MEMBER value) ...) ...)`
- `(+types (type NAME type_spec) ...)`
- `(+import package_name ...)`

Important boundary rules:

- `+size` entries require one signal name plus one positive width expression or
  named type.
- The legacy empty `(+size)` no-op remains default-mode compatibility residue;
  strict mode rejects it.
- `+constants`, `+params`, `+enums`, `+types`, and `+import` require non-empty
  payloads.
- `+define` carries exactly one `(NAME value)` pair in the current active
  contract.
- `+import` is a flat list of HDL-identifier-compatible package names.
- Whole aggregate roots are not scalar width expressions. Use a scalar leaf
  such as `LANES[1]`, or a named aggregate type alias when the target is typed
  aggregate storage.
- Dependency cycles in constants, params, and types are rejected before HDL
  emission.

Those constraints are part of the public language boundary. They keep invalid
declarations from falling through to Perl list-unpacking errors, raw backend
warnings, or accidental target-HDL behavior.

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
SystemVerilog-style based literals, `0x` / `0b` / `0o` prefixes, or FSMGen
intent-level sized literals such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`,
and `20'x1`. Bounded literal list/record payloads are also accepted when they
can lower to one packed literal. That keeps the authoring surface convenient
while preserving a concrete semantic value before generation.

One new hardening rule applies in these value lanes: obviously bitstring-like
bare `0/1` tokens such as `00001110` or `10000000` are rejected instead of
being guessed. Use `0b00001110`, `8'b00001110`, or `0d1110` explicitly.

Parameter values may also use bounded operator expressions:

```lisp
(+params
  (WIDTH 16)
  (BYTES (8'hA5 8'h3C))
  (BYTE_MASK (8'hF0 8'h0F))
  (COUNT_PLUS_ONE (+ WIDTH 1))
  (BYTE_PLUS_ONE (+ BYTES[1] 1))
  (MODE_PLUS_ONE (+ FRAME.meta.mode 1))
  (MASKED (and 8'hF0 8'h3C))
  (BYTES_MASKED (and BYTES BYTE_MASK))
)
```

The current expression operators are `+`, `-`, `*`, `/`, `%`, `&`, `|`, and
`^`, with word aliases `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and
`xor`. Scalar expressions may use scalar parameter/generic operands, including
scalar leaves inside list/record aggregate constants, package aggregate values,
and aggregate parameter defaults, for example `BYTES[1]`, `FRAME.flag`, or
`NESTED.meta.mode`. Width inference stays conservative for scalar expression
defaults.

This is not a scalar-only parameter/generic model.

Parameter/generic values are semantic values and may be scalar or aggregate.

Aggregate values can be declared, reused, overridden, shape-checked, and
packed where the existing paths support them.

The first aggregate-expression slices now support leafwise numeric and
bitwise operators `+`, `-`, `*`, `/`, `%`, `&`, `|`, and `^`, plus `add`,
`sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor` aliases, between matching
list/record aggregate shapes. They also support binary aggregate comparison
with `==` and `!=` between matching list/record shapes.

Those expressions are folded leaf-by-leaf into one aggregate value before
backend lowering.

Unary bitwise complement is also supported on one aggregate operand through
`(~ VALUE)` or `(not VALUE)`. It keeps the same list/record shape and scalar
leaf widths, and flips each scalar leaf bit before backend lowering.
Aggregate comparison folds to a scalar exact-width `1'b1` or `1'b0` before
backend lowering.

Arithmetic leaves are unsigned and fixed-width: each leaf width must match,
division or modulo by zero is rejected, and overflow/underflow outside that
leaf width aborts before generation.

The supported aggregate-operator surface is currently limited to semantic
parameter/generic values. It applies to direct `+params`, composition
parameter overrides, generated-child parameter overrides, and `.rtlif`
parameter/generic defaults after their values resolve to semantic payloads.
It does not mean that runtime `.fsm` or `.isf` expressions can operate on
whole aggregate values.

Examples:

```lisp
(+constants
  (LANES_A (8'hA5 8'h3C))
  (LANES_B (8'h01 8'h02))
  (FRAME_A ((mode 2'b10) (flag 1)))
  (FRAME_B ((mode 2'b01) (flag 0))))

(+params
  (LANES_SUM (+ LANES_A LANES_B))
  (LANES_MASK (& LANES_A LANES_B))
  (FRAME_OR (or FRAME_A FRAME_B))
  (LANES_INV (~ LANES_A))
  (FRAME_INV (not FRAME_A))
  (LANES_MATCH (== LANES_A LANES_A))
  (FRAME_DIFF (!= FRAME_A FRAME_B)))
```

`LANES_SUM` is folded by adding each matching list item. `LANES_MASK` is
folded by applying bitwise `&` to each matching list item. `FRAME_OR` is
folded by applying bitwise `|` to each matching record member while preserving
the authored record member order. `LANES_INV` and `FRAME_INV` apply unary
bitwise complement to each scalar leaf while preserving the original aggregate
shape. `LANES_MATCH` and `FRAME_DIFF` compare the packed matching aggregate
payloads and fold to scalar `1'b1`/`1'b0` values.

Richer aggregate operators beyond those matching-shape numeric, bitwise,
unary complement, and binary comparison forms remain future work until their
type/shape/result contracts are explicit enough to validate before generation;
that widening is tracked in [Feature Backlog](14-feature-backlog.md).

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

## Using Symbols In Widths

`+size` width entries are constant-expression slots too. That means you can
name width ingredients once and reuse them without littering the source with
magic numbers:

```lisp
(+constants
  (BYTE_W 8)
  (LANES (4 8))
)
(+enums
  (mode_w
    (CTRL 4)
    (DATA 8)
  )
)
(+params
  (EXTRA_W 1)
  (CTRL_W (+ BYTE_W EXTRA_W))
)
(+size
  (payload (+ BYTE_W EXTRA_W))
  (mode mode_w.DATA)
  (lane LANES[1])
  (ctrl CTRL_W)
)
```

The resolved value must be one positive integer before generation. Named types
still work in this same slot, so `(+size (frame frame_t))` remains the way to
attach a declared aggregate/scalar type rather than computing a raw width.

Positive integer scalar symbols used as direct `+size` widths or composition
`?ports` widths accept the same common scalar literal spellings, so a shared
`(BYTE_W 0x8)` or `(BYTE_W 'h8)` can safely drive a width contract.

Aggregate scalar leaves may participate too, for example `LANES[1]` or
`FRAME.meta.mode`, but a whole aggregate root such as `LANES` is not itself a
scalar width. Use a scalar leaf when computing a raw width, or use a declared
aggregate type alias when the intent is typed aggregate storage.

The direct `+size` expression path and the scalar-width-symbol path share the
same integer literal interpreter for decimal, `0d`, `0b`, `0o`, `0x`,
SystemVerilog-style based spellings, and FSMGen intent-level sized values.

Signed literal terms are valid ingredients when the final width remains
positive, for example:

```lisp
(+params
  (DEC_W (+ 0d10 -2))
)
(+size
  (from_param DEC_W)
  (from_terms (+ 8'sd9 8'sd-1))
)
```

Width arithmetic must still be fully valid before HDL generation. Division or
modulo by zero, unsupported operators, malformed arity, unresolved symbols, and
non-positive final widths are rejected as language-contract errors instead of
being delegated to the backend.

For example, `(pow 2 3)` is intentionally rejected today because `pow` is not
part of the bounded width-expression operator set.

Likewise, `(+ 8)` is rejected because the supported infix-style width
operators require at least two operands.

Expressions such as `(/ 8 0)` or `(% 8 0)` are rejected before HDL generation
because width declarations must fold to one well-defined positive integer.

## Constants

Use `+constants` for named scalar values and bounded aggregate values.

Simple scalar example:

```lisp
(+constants
  (RESET_BYTE 8'hA5)
  (RESET_ALIAS 0xA5)
  (LANE_MASK 0b1010)
  (OCT_W 0o10)
  (IDLE_MASK 8'h03)
)
```

Scalar constants accept the common integer spellings used elsewhere in the
language: plain decimal, sized SystemVerilog literals, unsized
SystemVerilog-style based literals such as `'hA5`, prefixed forms such as
`0xA5`, `0b1010`, and `0o77`, FSMGen intent-level sized values such as
`5'23` or `8'-0xA`, plus underscore-separated digits.

For value-bearing constants, FSMGen also rejects obviously bitstring-like bare
`0/1` tokens such as `00001110` or `10000000`. Use `0b...`, `N'b...`, or an
explicit decimal `0d...` spelling so the source stays unambiguous before HDL
generation.

FSMGen intent-level sized literals use `<width>'<integer-value>` in `.fsm`.

They are source-language values, not target-HDL text escapes. The backend must
normalize them before emission, so `5'23` lowers to legal SV like `5'd23`,
`20'x1` lowers to `20'h1`, and negative sized values lower as two's-complement
bit patterns such as `8'-10` -> `8'd246`, `8'-0xA` -> `8'hF6`, and
`8'-0b1010` -> `8'b11110110`.

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
- `(bits WIDTH_SYMBOL)`
- `(signed bit)`
- `(signed (bits N))`
- `(signed (bits WIDTH_SYMBOL))`
- `(two_state TYPE)`
- `(four_state TYPE)`
- named aliases to other scalar types

Examples:

```lisp
(+constants
  (WORD_W 32)
)

(+types
  (type flag bit)
  (type byte (bits 8))
  (type word (bits WORD_W))
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

This is not a complete portable type core yet. Enum families still use the
existing `+enums` declaration family, and fixed-size arrays / arrays of
records remain future work rather than accepted `+types` forms.

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

Direct-root `+size`, composition `?ports`, and scalar `+types` `(bits ...)`
widths may now come from:

- raw positive integers
- local scalar type aliases
- imported package-qualified scalar type aliases
- local positive integer scalar symbols
- imported positive integer scalar symbols

For `+size` and composition `?ports`, width expressions also retain the
broader already-shipped constant-expression surface where documented. For
`+types` `(bits WIDTH_SYMBOL)`, the accepted symbol must resolve directly to a
positive integer scalar constant or enum member in the available symbol scope.
Aggregate scalar leaves, runtime signals, parameters, and arbitrary
expressions are intentionally not accepted as type-width symbols.

Those scalar width symbols use the same positive-integer literal
interpretation as direct `+size` scalar terms, including decimal, `0d`, `0b`,
`0o`, `0x`, SystemVerilog-style based spellings, and intent-level sized
values. This keeps a package constant such as `(BYTE_W 0d8)` or `(BYTE_W 'h8)`
usable anywhere a positive width scalar symbol is allowed.

Example:

```lisp
(+constants
  (BYTE_W 8)
)

(+types
  (type byte (bits BYTE_W))
)
```

Enum members are also valid width symbols:

```lisp
(+enums
  (width_e
    (NIBBLE 4))
)

(+types
  (type nibble (signed (bits width_e.NIBBLE)))
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
- scalar type aliases, including signed and two-state/four-state intent
- packed list and record aliases
- semantic imports from `?pkg`
- declared-type preservation across the live pipeline
- direct generated-module packed typedef emission for aggregate aliases
- composition-top packed typedef emission for aggregate aliases
- direct-root typed aggregate signal member/list-item access in expressions
  and partial aggregate LHS writes on the SystemVerilog path
- typed aggregate top-port and generated-child source paths in composition
  `?wiring`
- symbol-contract, `Intent HIR`, `module_info`, and `Structural RTL IR`
  preservation for the bounded type surface

These items are also tracked in the consolidated
[Feature Backlog](14-feature-backlog.md):

- broader inference-first typing so users need fewer explicit anchors
- broader inference-first aggregate member/index typing without explicit
  declared aggregate anchors
- fixed-size arrays, arrays of records, and full enum-as-type unification
- VHDL aggregate-type lowering beyond current scalar/width-safe surfaces
- richer public type/export surfaces for embedders
