# Composition Advanced

This chapter covers the richer source-side expression and structural-actual
features of `?toplink`.

The guiding rule is simple:

- authoring should stay expressive
- planning should stay typed and deterministic
- generation should not invent fake top ports or fake helper nets just to hide
  semantic gaps

## Source-Side Expressions

The source side of a `?toplink` can now be more than a plain port name.

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
(?toplink:wiring
  /payload_bus[15:8]/byte_sink.data_in/
  /producer.payload[7:4]/consumer.nibble_in/
  /in_frame.tag/tag_out/
  /producer.OUT_FRAME.payload[1]/consumer.payload_mid/
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
- `=FRAME`
- `=shared.RESET_BYTE`

Current rule of thumb:

- direct bindings may widen unsized numeric actuals to the direct target width
- concat operands do not borrow width from the target
- exact-width literals stay exact-width contracts

## Concat Sources

Bounded source-side concat is a first-class shipped feature.

```lisp
(?toplink:wiring
  /header_bus,status_bus[0],=1,payload_bus[3:0]/uart_tx.data_in/
)
```

Nested brace groups are also preserved:

```lisp
(?toplink:wiring
  /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/
)
```

Concat operands may currently include:

- whole top ports
- top-port bit/slice forms
- declared aggregate top-port member/item forms such as `in_frame.tag`
- child-output operands
- scalar actuals
- intrinsic-width unsized based literals
- intrinsic-width unsized decimal and signed-decimal literals
- exact-width signed and unsigned literals
- named literal actuals
- repeat groups

## Repeat Groups

Repeat groups now ride the same typed structural path as other source
expressions.

```lisp
(?toplink:wiring
  /{3{status_bus[0]}}/child.data_in/
  /{2{producer.serial_lo}}/packed_out/
)
```

## Omitted `?ports` Inference

In explicit-link tops, omitted or empty `?ports` can still be honest when the
links themselves define the boundary clearly.

Example:

```lisp
(?top:uart_slice_top
  (?rtl:byte_sink)
  (?toplink:wiring
    /payload_bus[15:8]/byte_sink.data_in/
    /status_bus[0]/byte_sink.enable/
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
(?toplink:wiring
  /in_frame.tag,payload/sink.data_in/
)
```

If `in_frame` is already declared with an aggregate type, or has been inferred
as one aggregate contract from another whole-root link to a typed child input
in the same `?toplink` block, or can be seeded from an unlinked same-name child
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

This matters because the top boundary should not force needless helper nets
when the intended wiring is already explicit.

## Declared Type Compatibility

Composition no longer relies only on packed width when named aliases preserve
declared type identity.

That declared type information now affects:

- same-name undeclared top-port inference
- plain explicit top-port convention
- declared `=name` connect-by-name
- explicit plain port-to-port `?toplink`
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
  (?toplink:wiring
    /=FRAME/packed_out/
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
  (?toplink:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
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
still a future backend follow-up.

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
  (?toplink:wiring
    /payload_in/u_child.in_data/
    /u_child.out_data/payload_out/
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

## Current Boundary

This advanced lane is deliberately rich but still bounded:

- source-side expressions are source-side only
- concat and repeat stay bounded structural forms
- actuals are typed, not raw text escape hatches
- inference is allowed only when one honest answer exists
- explicit mismatches fail before emission

For the exact accepted families, keep
[COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) beside this chapter.
