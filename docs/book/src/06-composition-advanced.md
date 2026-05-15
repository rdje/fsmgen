# Composition Advanced

This chapter covers the richer source-side expression and structural-actual
features of `?wiring`.

The guiding rule is simple:

- authoring should stay expressive
- planning should stay typed and deterministic
- generation should not invent fake top ports or fake helper nets just to hide
  semantic gaps

## Source-Side Expressions

The source side of a `?wiring` can now be more than a plain port name.

Current shipped source-side families include:

- top-port bit selects like `status_bus[0]`
- top-port slices like `payload_bus[15:8]`
- typed aggregate top-port member/item sources like `in_frame.tag` and
  `in_frame.payload[1]`
- child-output bit selects like `producer.payload[0]`
- child-output slices like `producer.payload[7:4]`
- typed aggregate generated-child output member/item sources like
  `producer.OUT_FRAME.tag` and `producer.OUT_FRAME.payload[1]`
- bounded concat expressions
- bounded repeat groups

Example:

```lisp
(?wiring:wiring
  (payload_bus[15:8] byte_sink.data_in)
  (producer.payload[7:4] consumer.nibble_in)
  (in_frame.tag tag_out)
  (producer.OUT_FRAME.payload[1] consumer.payload_mid)
)
```

For typed aggregate member/item sources, the base endpoint must preserve a
declared aggregate type. Record members use their authored names. List items
use authored `[N]` syntax in `.fsm`, and the current SystemVerilog lowering
maps that to the generated packed-list field name such as `.item_1`.

When the base is a generated child output, FSMGen still follows the normal
projected-child-source rule: it creates one typed carrier for the whole child
output, binds the child output to that carrier, and then applies member/item
access to the carrier for each target.

Source-side expressions may target realized child inputs or declared top
outputs where the current typed structural path supports that binding. If an
expression targets a typed aggregate port, the expression must carry one
compatible aggregate contract; matching by packed width alone is not enough.

## Structural Actuals

The live explicit-actual family is intentionally broad but typed.

Examples:

- `=open`
- `=0`
- `=1`
- `=170`
- `=0xA5`
- `='hA5`
- `=8'hA5`
- `=8'sd-1`
- `=5'23`
- `=8'-0xA`
- `=20'x1`
- `=FRAME`
- `=shared.RESET_BYTE`

Current rule of thumb:

- direct bindings may widen unsized numeric actuals to the direct target width
- concat operands do not borrow width from the target
- exact-width literals stay exact-width contracts
- FSMGen intent-sized exact-width literals such as `=5'23`, `=8'-10`, `=8'-0xA`, `=8'-0b1010`, or `=20'x1` are accepted on both direct-actual and concat-operand lanes
- obviously bitstring-like bare `0/1` actuals such as `=00001110` or `=10000000` are rejected instead of guessed; use `=0b...`, `=N'b...`, or `=0d...`
- `=open` is currently valid only for realized child input ports
- fixed-width binary/octal/hex actuals must match the direct target width
  exactly
- decimal actuals must fit the target width as numeric values
- unsized signed actuals must fit the signed range of the direct target width
- whole aggregate actual roots such as `=FRAME` or `=shared.FRAME` must lower
  to scalar leaves and must match any preserved target aggregate type contract

Concrete example:

```lisp
(?top:composition_intent_integer_literals
  (?ports:public_io
    decimal_out>5
    negative_out>8
    packed_out>33
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    (=5'23 decimal_out)
    (=8'-0xA negative_out)
    ((cat =5'23 =8'-10 =20'x1) packed_out)
    (=5'23 uart_tx.decimal_in)
    (=8'-0b1010 uart_tx.negative_in)
    ((cat =5'23 =8'-0xA =20'x1) uart_tx.packed_in)
  )
)

(?rtlif:uart_tx
  decimal_in<5:data
  negative_in<8:data
  packed_in<33:data
)
```

That example shows both direct actual and concat actual lowering:

- `=5'23` stays one 5-bit exact-width operand
- `=8'-0xA`, `=8'-10`, and `=8'-0b1010` all normalize through the same checked two's-complement path
- `=20'x1` stays one 20-bit exact-width operand
- direct top-output and child-input bindings emit those literals directly
- concat bindings keep the operand widths `5 + 8 + 20` instead of borrowing width from `packed_out`

Maintained repo examples:

- [direct_intent_integer_literals.fsm](t/corpus/direct_intent_integer_literals.fsm)
- [composition_intent_integer_literals.fsm](t/corpus/composition_intent_integer_literals.fsm)

## Concat Sources

Bounded source-side concat is a first-class shipped feature.

```lisp
(?wiring:wiring
  ((cat header_bus status_bus[0] =1 payload_bus[3:0]) uart_tx.data_in)
)
```

Nested brace groups are also preserved:

```lisp
(?wiring:wiring
  ((cat header_bus
        (cat status_bus[0] =0b1_0)
        (cat payload_bus[3:2] payload_bus[1:0]))
   uart_tx.data_in)
)
```

The compatibility source-token spelling remains accepted too, so older sources
like `/header_bus,status_bus[0],=1,payload_bus[3:0]/uart_tx.data_in/` still
parse. In new code, prefer `(source target)` and use `(cat ...)` when the
source is a concat expression.

Concat operands may currently include:

- whole top ports
- top-port bit/slice forms
- declared aggregate top-port member/item forms such as `in_frame.tag`
- child-output operands
- scalar actuals `=0` and `=1`
- intrinsic-width unsized based literals such as `=0b10`, `='b10`, `=0o7`,
  `='o7`, `=0xA5`, `='hA5`, or `=A5`
- intrinsic-width unsized decimal and signed-decimal literals such as `=170`,
  `=0d170`, `='d170`, `=-1`, `=0d-1`, or `='sd-1`
- exact-width signed and unsigned binary/decimal/octal/hex literals
- named literal actuals from top-root constants/enums or imported packages
- repeat groups

The same ambiguity hardening applies here too: bare `=00001110`-style
payloads are not guessed as decimal or binary.

Nested brace groups are source-side concat grouping, not target-HDL text pasted
through unchecked. The source frontend preserves those groups so the structural
path can validate width/type evidence before the emitter renders HDL.

## Repeat Groups

Repeat groups now ride the same typed structural path as other source
expressions.

```lisp
(?wiring:wiring
  ((repeat 3 status_bus[0]) child.data_in)
  ((repeat 2 producer.serial_lo) packed_out)
)
```

The verbose directed-link spelling is equivalent:

```lisp
(?wiring:wiring
  (connect (repeat 3 status_bus[0]) child.data_in)
  (connect (repeat 2 producer.serial_lo) packed_out)
)
```

## Omitted `?ports` Inference

In explicit-link tops, omitted or empty `?ports` can still be honest when the
links themselves define the boundary clearly.

Example:

```lisp
(?top:uart_slice_top
  (?rtl:byte_sink)
  (?wiring:wiring
    (payload_bus[15:8] byte_sink.data_in)
    (status_bus[0] byte_sink.enable)
  )
)
```

This infers:

- `payload_bus` as an input of at least width 16
- `status_bus` as an input of width 1

The same inference path also understands bounded concat and bounded repeat
groups, but it still refuses ambiguous multi-operand guessing.

Declared aggregate top-port paths can now help that inference too:

```lisp
(?wiring:wiring
  ((cat in_frame.tag payload) sink.data_in)
)
```

If `in_frame` is already declared with an aggregate type, or has been inferred
as one aggregate contract from another whole-root link to a typed child input
in the same `?wiring` block, or can be seeded from an unlinked same-name child
input with one uniform record/list declared-type contract, and `in_frame.tag`
is four bits, FSMGen can use that exact leaf width while sizing the remaining
omitted whole operand `payload` from the target remainder. If `in_frame` has
no declared or inferred aggregate contract, FSMGen fails explicitly instead of
guessing an aggregate shape from the member name alone.

## Top Outputs And Fanout

The explicit-link boundary can now also:

- fan one child output out to multiple top outputs
- drive one or more top outputs directly from a declared top input
- drive declared top outputs from top expressions or literal actuals
- infer same-name internal carriers when one unique child output and one or
  more child inputs share a compatible name family and no explicit link already
  owns that family

This matters because the top boundary should not force needless helper nets
when the intended wiring is already explicit.

Inferred internal carriers stay internal by default. A declared compatible top
output may explicitly re-export one of them through the same-name convention,
but FSMGen does not silently publish internal carriers as top outputs.

## Declared Type Compatibility

Composition no longer relies only on packed width when named aliases preserve
declared type identity.

That declared type information now affects:

- same-name undeclared top-port inference
- plain explicit top-port convention
- declared compact `=name` or verbose `:same-name` connect-by-name
- explicit plain port-to-port `?wiring`
- inferred internal carrier nets
- whole aggregate direct actual binding

So width-equal but type-incompatible endpoints now fail explicitly instead of
slipping through.

That same declared aggregate identity now reaches the emitted SystemVerilog
surface too. When a composition top port or typed structural net preserves a
named aggregate alias, the structural emitter now synthesizes one backend-owned
packed typedef for it instead of flattening everything back to raw vectors.

- record aliases keep authored field names
- list aliases become deterministic packed structs with `item_0`, `item_1`,
  ... field names
- imported aliases are sanitized into local emitted typedef identifiers such as
  `shared_types__frame_t__fsmgen_t`

## Typed Shared-Datapath Families

The shared-datapath lane is conservative when typed child outputs are involved.

- same-name child-output families still need exact name, width, and interface
  agreement
- and when those child outputs also preserve declared type identity from named
  aliases, the shared-datapath family only forms when that typed contributor
  evidence remains compatible too

That means width-equal but declared-type-incompatible outputs do not collapse
into one shared-datapath family just because they are both called `status_bus`.

When the typed contributor evidence is uniform, the candidate metadata keeps
that declared type contract and the private raw contributor nets synthesized by
shared-datapath lifting preserve the same contributor-side type identity in the
structural export.

The lifted runtime carriers now follow that same rule too:

- `*_shared_q`
- `*_shared_next`
- `*_shared_comb`

They are now explicit structural nets with a real declaration kind instead of
existing only as declaration text hidden in auxiliary HDL sections.

## Whole Aggregate Actuals

Whole aggregate roots such as `=FRAME` are now live on the typed actual path.

Example:

```lisp
(?top:typed_actual_top
  (+constants
    (FRAME
      (mode 2'b10)
      (flag 1))
  )
  (+types
    (type frame_t (record (mode (bits 2)) (flag bit)))
  )
  (?ports:public_io
    packed_out>frame_t
  )
  (?wiring:wiring
    (=FRAME packed_out)
  )
)
```

If the target preserves an incompatible aggregate type contract, the binding is
blocked even if the packed widths match.

## External RTL Metadata Categories

`.rtlif` port categories are currently:

- `data`
- `clock`
- `reset`

Those are interface-role categories, not HDL data types. They help composition
plan system lanes and ordinary data lanes honestly.

`clock` and `reset` are currently system-input roles. A token such as
`core_clk:clock` or `rst_async_n:reset` may auto-wire a custom-named RTL system
input, but `core_clk>:clock` and `rst_async_n>:reset` are rejected because they
claim that the external RTL child drives the system lane. Use `data` for
ordinary payload/status outputs, for example `txd>:data`.

The role suffixes also have verbose nullary-attribute spellings:

```lisp
(?rtlif:uart_tx
  (input core_clk :clock)
  (input rst_async_n :reset)
  (input data_in (width 16) :data)
  (output txd :data)
)
```

This is equivalent to:

```lisp
(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)
```

The parenthesized forms `(clock)`, `(reset)`, and `(data)` are accepted aliases
for `:clock`, `:reset`, and `:data`. The direction keyword still owns
input-versus-output semantics; the role owns composition metadata.

Verbose width stays in the `(width N)` attribute. A spelling such as
`(input data_in:16 :data)` is intentionally not a width shorthand because
colon already separates role metadata in compact `.rtlif` tokens.

`?rtl` also has a reusable-instance form. `(?rtl:module)` means the instance
name equals the module/interface name. `(?rtl:instance module)` means “create
instance `instance` of external RTL module `module`,” and the corresponding
`.rtlif` root remains `(?rtlif:module ...)`.

Per-instance parameter/generic overrides are now a semantic instantiation
contract, not a raw target-HDL text escape hatch. Declare the parameter/generic
names and defaults in the external interface contract, then override them on
the specific `?rtl` instance:

```lisp
(?top:parameterized_rtl_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (LOCAL_LANES (8'hA5 8'h3C))
  )
  (+enums
    (frame_mode
      (RUN 2'b10)
    )
  )
  (+import
    param_pkg
  )
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH OVERRIDE_WIDTH)
      (RESET_VALUE param_pkg.RESET_A5)
      (LANES LOCAL_LANES)
      (FRAME ((mode frame_mode.RUN) (flag param_pkg.FLAG_ON)))
    )
  )
  (?wiring:wiring
    (payload_in u_uart.data_in)
    (u_uart.txd serial_out)
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.DEFAULT_WIDTH)
    (RESET_VALUE param_pkg.DEFAULT_RESET)
    (LANES param_pkg.DEFAULT_LANES)
    (FRAME param_pkg.DEFAULT_FRAME)
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (DEFAULT_WIDTH 8)
    (DEFAULT_RESET 8'h00)
    (DEFAULT_LANES (8'h00 8'h00))
    (DEFAULT_FRAME ((mode 2'b00) (flag 0)))
    (RESET_A5 8'hA5)
    (FLAG_ON 1)
  )
)
```

The same interface ports may be authored verbosely below the same parameter
block:

```lisp
(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.DEFAULT_WIDTH)
    (RESET_VALUE param_pkg.DEFAULT_RESET)
    (LANES param_pkg.DEFAULT_LANES)
    (FRAME param_pkg.DEFAULT_FRAME)
  )
  (input core_clk :clock)
  (input rst_async_n :reset)
  (input data_in (width 16) :data)
  (output txd :data)
)
```

The shipped value surface accepts scalar integer literals such as `8`, `8'hA5`,
`'hA5`, `0xA5`, `0b1010`, and `0o77`, plus bounded literal aggregate payloads
such as `(8'hA5 8'h3C)` and `((mode 2'b10) (flag 1))`. It also accepts resolved
composition-top and imported-package symbols for instance overrides, including
enum members and whole aggregate roots. `.rtlif` declaration defaults may use
literal values or package-qualified symbols from packages imported by the
consuming composition source, such as `param_pkg.DEFAULT_WIDTH` or
`param_pkg.DEFAULT_LANES`; they deliberately do not depend on unqualified
top-local names so sidecar metadata stays reusable. Overrides must name entries
in the `.rtlif` `(params ...)` block. Aggregate overrides must also match the
aggregate shape inferred from the `.rtlif` default value before generation
continues. Unresolved symbolic declaration defaults or override values fail
after package import resolution and before planning or HDL emission. Validated
values survive into the composition plan and structural RTL IR, and the current
Verilog-family backend lowers them to SystemVerilog `#(...)` instance
parameters by packing aggregates into one literal. VHDL generic-map lowering is
still a future backend follow-up tracked in
[Feature Backlog](14-feature-backlog.md).

Parameter/generic values on this path may also use bounded operator
expressions such as `(+ WIDTH 1)`, `(* COUNT 2)`, or `(and MASK 8'hF0)`. Those
expressions resolve semantic scalar operands before planning and lower as
parenthesized scalar parameter expressions. Scalar leaves inside list/record
aggregate values are valid operands, including nested leaves such as
`shared.FRAME.meta.mode` or `LOCAL_BYTES[1]`.

Parameter/generic values are not scalar-only. Scalars and aggregates are both
valid semantic parameter/generic values on the composition surface where the
declared/default contracts allow them. The first aggregate operator slice
supports leafwise numeric and bitwise operators `+`, `-`, `*`, `/`, `%`, `&`,
`|`, and `^`, plus `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor`
aliases, between matching list/record aggregate shapes. The normalizer folds
those expressions leaf-by-leaf into one aggregate value before the composition
plan reaches HDL lowering. Arithmetic leaves are unsigned fixed-width values:
leaf widths must match, division or modulo by zero is rejected, and
overflow/underflow outside that leaf width aborts before generation. Richer
aggregate operators remain future work until the specific operator is defined
for the operand aggregate types/shapes and the result can be validated before
generation. That widening is tracked in
[Feature Backlog](14-feature-backlog.md).

Generated `?fsmc` and `?dtc` children now use the same semantic override
surface, but the declaration contract lives in the realized child source's
direct `(+params ...)` block rather than in `.rtlif` metadata:

```lisp
(?top:parameterized_generated_child_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (TOP_LANES (8'hA5 8'h3C))
  )
  (?ports:public_io
    clk
    rstn
    payload_in<16
    payload_out>16
  )
  (?fsmc:u_child child_src
    (params
      (WIDTH OVERRIDE_WIDTH)
      (LANES TOP_LANES)
    )
  )
  (?wiring:wiring
    (payload_in u_child.in_data)
    (u_child.out_data payload_out)
  )
)

(?fsm:child_src
  (+params
    (WIDTH 8)
    (LANES (8'h00 8'h00))
  )
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (in_data 16)
    (out_data 16)
  )
  (-idle
    (out_data> = LANES <in_data=WIDTH)
  )
)
```

The parser accepts at most one `(params (NAME value) ...)` block under each
generated-child instance. Symbolic override values resolve after composition
imports, undeclared override names fail against the generated child's direct
`+params` declarations, scalar overrides stay width-flexible, aggregate
overrides must match the child default's aggregate shape, and current
Verilog-family emission lowers valid generated-child overrides to
SystemVerilog `#(...)` instance parameters. VHDL generic-map lowering remains a
backend follow-up.

The same bounded expression value surface is accepted for generated-child
overrides and for the direct `+params` defaults declared in the generated child
source. For example, `(params (WIDTH_PLUS_ONE (+ WIDTH 1)))` stays semantic:
the operands resolve before generation, then the current Verilog-family backend
emits a normal instance parameter expression rather than raw user text. Aggregate
bitwise overrides such as `(params (LANES_MASKED (and LANES LANE_MASK)))` fold
through the same aggregate shape checks before instance emission.

## Current Boundary

This advanced lane is deliberately rich but still bounded:

- source-side expressions are source-side only
- concat and repeat stay bounded structural forms
- actuals are typed, not raw text escape hatches
- inference is allowed only when one honest answer exists
- explicit mismatches fail before emission

For implementation scoping and historical mapping details, keep
[COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) beside this chapter, but the
user-facing accepted families above belong in the book.
