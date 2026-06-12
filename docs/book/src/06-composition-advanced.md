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
source is a concat expression. In strict mode, the slash-token spelling is
rejected as composition compatibility residue; write the same movement as
`((cat header_bus status_bus[0] =1 payload_bus[3:0]) uart_tx.data_in)` or
`(connect (cat header_bus status_bus[0] =1 payload_bus[3:0])
uart_tx.data_in)`.

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

Composition-top `+constants` and `+enums` may feed named literal actuals, but
the top symbol declarations are still literal-contract declarations. Symbol
names must be HDL identifiers, and top enum values must resolve to literal
scalar values before the composition planner uses them.

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

```text
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

## Shared-Datapath Families

FSMGen can recognize a bounded shared-datapath family when a composition top
contains multiple realized generated FSM children (`?fsmc`) that expose an
output with the same name, width, interface type, and compatible declared type
identity.

The feature is inferred from the child interfaces and wiring. There is no
separate user syntax that asks for a shared datapath. A family such as
`status_bus` forms only when the contributors are compatible enough for FSMGen
to build one deterministic shared carrier.

Example:

```text
(?top:shared_status_top
  (?ports:public_io
    clk
    rstn
    select
    left_status>8
    right_status>8
    result_data>8
  )
  (?fsmc:left left_src)
  (?fsmc:right right_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    /select/left.select/
    /select/right.select/
    /select/consumer.select/
    /left.status_bus/left_status/
    /left.status_bus/consumer.status_bus/
    /right.status_bus/right_status/
    /consumer.result_data/result_data/
  )
)
```

If both `left_src` and `right_src` drive an output named `status_bus` with the
same width and type, FSMGen records one shared-datapath candidate for that
family.

### Candidate Metadata

Each candidate is reported through the composition result metadata and the
normalized semantic surfaces as `composition_shared_datapath_candidates`.

The shipped candidate surface includes:

- shared signal name, width, interface type, and optional declared type
  contract
- contributor instance/module/endpoint identity
- contributor binding information from the structural connection-expression
  surface
- each contributor's `intent_hir`, `lowered_rtl_ir`, `structural_rtl_ir`, and
  selected output-drive-family summary
- top outputs that currently expose the family
- peer child inputs that read the family
- storage class: `registered`, `combinational`, `mixed`, or `unknown`
- default lifted-visibility planning
- aggregate enable, same-value conflict, and multi-value conflict signals
- bounded assertion metadata for same-value and multi-value conflicts

The non-quiet CLI also prints a concise `Shared-Datapath Candidates` summary
from that same metadata.

### Typed Compatibility

The shared-datapath lane is conservative when typed child outputs are involved.

Same-name child-output families still need exact name, width, and interface
agreement. When those child outputs also preserve declared type identity from
named aliases, the family only forms when that typed contributor evidence is
compatible too.

That means width-equal but declared-type-incompatible outputs do not collapse
into one shared-datapath family just because they are both called `status_bus`.

When the typed contributor evidence is uniform, the candidate metadata keeps
that declared type contract. Private raw contributor nets synthesized by
shared-datapath lifting preserve the contributor-side type identity in the
structural export.

The lifted runtime carriers follow the same rule:

- `*_shared_q`
- `*_shared_next`
- `*_shared_comb`

They are explicit structural nets with a real declaration kind instead of
existing only as declaration text hidden in auxiliary HDL sections.

### Enable And Conflict Signals

For each RHS value in a shared family, FSMGen builds per-contributor
source-enable aliases and one aggregate value-enable signal.

For the whole family, FSMGen also builds one aggregate target-enable signal
and one multi-value conflict signal.

SystemVerilog composition tops emit verification-only guard assertions under
`` `ifndef SYNTHESIS``:

- same-value assertions detect more than one contributor selecting the same
  value family in the same cycle
- multi-value assertions detect more than one value family becoming active in
  the same cycle

Verilog targets keep the assertion metadata, but they do not emit
SystemVerilog assertion syntax.

### Registered Runtime

When a shared family is registered, has a consistent reset value, and the
composition top has usable clock/reset system signals, FSMGen can lift the
family into one top-level shared register.

For a peer-read public-preserving case, the generated top emits:

- one `*_shared_next` signal
- one `*_shared_q` register
- next-value mux logic driven by the aggregate value enables
- an `always_ff` block with the recovered reset value
- private `shared_dp_raw_*` nets for each child contributor output
- peer child inputs rebound to `*_shared_q`
- public top outputs assigned from `*_shared_q`

Registered internal-only peer-read families use the same lifted register and
peer-input rebinding, but FSMGen does not invent public re-export assignments.

Registered public-fanout families with no peer-read child inputs also lift to
one shared register and assign each preserved public top output from it.

Mixed public/internal registered families preserve public top re-exports and
avoid invented internal-carrier publication.

### Combinational Runtime

Combinational shared families never become lifted state.

When the family has public top outputs or top-local peer reads, FSMGen can
lift it into one `*_shared_comb` carrier. The generated top emits
`always_comb` value-family mux logic, private raw contributor nets, and the
appropriate rebinding:

- public-preserving peer-read families rebind peer child inputs to
  `*_shared_comb` and assign public top outputs from it
- internal-only peer-read families rebind peer child inputs to a top-local
  `*_shared_comb` carrier without inventing public top outputs
- public-fanout families with no peer-read child inputs assign each preserved
  public top output from `*_shared_comb`

This is still combinational routing, not storage. FSMGen does not silently add
state for a combinational shared family.

### Current Boundary

The shipped shared-datapath contract is bounded to compatible same-name output
families across multiple realized generated FSM children.

The current implementation does not promise arbitrary route mux/storage,
general fan-in/fan-out protocols, ready/backpressure, payload protocols,
dynamic scheduling, or external-RTL/standalone-DT contributors as shared
datapath sources.

Mixed registered/combinational contributor families are reported as mixed or
unknown metadata, but they are not lifted into one runtime carrier.

Broader shared-data movement should be selected as a separate task-tree slice
only after the route/storage/protocol, reusable-module, portable-type, or
architecture contract is explicit.

## Whole Aggregate Actuals

Whole aggregate roots such as `=FRAME` are now live on the typed actual path.

Example:

```text
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

The shipped value surface accepts scalar integer literals such as `8`,
`8'hA5`, `'hA5`, `0xA5`, `0b1010`, and `0o77`, plus bounded literal aggregate
payloads such as `(8'hA5 8'h3C)` and `((mode 2'b10) (flag 1))`.

It also accepts resolved composition-top and imported-package symbols for
instance overrides, including enum members and whole aggregate roots.

`.rtlif` declaration defaults may use literal values or package-qualified
symbols from packages imported by the consuming composition source, such as
`param_pkg.DEFAULT_WIDTH` or `param_pkg.DEFAULT_LANES`; they deliberately do
not depend on unqualified top-local names so sidecar metadata stays reusable.

Importing `param_pkg` therefore makes the namespace available; it does not
make `DEFAULT_WIDTH` an unqualified local name.

`.rtlif` metadata should keep the package prefix so the default remains
reviewable, reusable, and unambiguous when multiple packages define similarly
named defaults.

Overrides must name entries in the `.rtlif` `(params ...)` block.

Aggregate overrides must also match the aggregate shape inferred from the
`.rtlif` default value before generation continues.

Unresolved symbolic declaration defaults or override values fail after
package import resolution and before planning or HDL emission.

Validated values survive into the composition plan and structural RTL IR, and
the current Verilog-family backend lowers them to SystemVerilog `#(...)`
instance parameters by packing aggregates into one literal.

Successful normalized semantic JSON reports expose those structural values
under `semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`.
The public contract advertises the core keys `name`, `origin_kind`,
`raw_value_ast`, `value_kind`, `value_payload`, and `value_text`; optional
extension families advertise `raw_value` when a single authored token is
preserved and `value_type_spec`/`value_width` when resolved value metadata is
available.

Composition top-output helper assignments surface separately under
`semantic.forward_ir.structural_rtl_ir.auxiliary_assignments[]`. Those entries
remain scalar strings containing the generated SystemVerilog assignment line.
Direct generated-enable roots now also expose machine-readable
`semantic.forward_ir.structural_rtl_ir.assignment_records[]` entries, but that
direct assignment-record surface is separate from the composition helper-line
mirror.

VHDL generic-map lowering is still a future backend follow-up tracked in
[Feature Backlog](14-feature-backlog.md).

## Current `.rtlif` Direction

`.rtlif` remains the canonical low-level external-RTL interface metadata
contract. It is intentionally not a full standalone interface-source language.
The shipped surface describes the RTL module boundary that composition needs
today: flat input/output ports, `data` / `clock` / `reset` roles, explicit
widths, optional semantic parameter/generic defaults, and per-instance
overrides that are validated before HDL emission.

Do not treat `.rtlif` as raw backend text or as a place to hide HDL-specific
module internals. FSMGen uses it to validate and wire external RTL children
without parsing or regenerating those children.

A stronger interface-source layer is deferred until a concrete future
requirement proves that the current metadata layer is not enough. Likely
prerequisites are the portable type core, richer package/import contracts,
shared-datapath ownership rules, or a broader reusable-module contract.

Parameter/generic values on this path may also use bounded operator
expressions such as `(+ WIDTH 1)`, `(* COUNT 2)`, or `(and MASK 8'hF0)`. Those
expressions resolve semantic scalar operands before planning and lower as
parenthesized scalar parameter expressions. Scalar leaves inside list/record
aggregate values are valid operands, including nested leaves such as
`shared.FRAME.meta.mode` or `LOCAL_BYTES[1]`.

Parameter/generic values are not scalar-only.

Scalars and aggregates are both valid semantic parameter/generic values on
the composition surface where the declared/default contracts allow them.

The first aggregate operator slice supports leafwise numeric and bitwise
operators `+`, `-`, `*`, `/`, `%`, `&`, `|`, and `^`, plus `add`, `sub`,
`mul`, `div`, `mod`, `and`, `or`, and `xor` aliases, between matching
list/record aggregate shapes.

Binary aggregate comparison is supported with `==` and `!=` between matching
list/record aggregate shapes. It folds to scalar exact-width `1'b1` or
`1'b0` before backend lowering.

The normalizer folds those expressions leaf-by-leaf into one aggregate value
before the composition plan reaches HDL lowering.

Unary bitwise complement is supported for one aggregate operand as
`(~ VALUE)` or `(not VALUE)`. It flips each scalar leaf and preserves the
aggregate shape.

Arithmetic leaves are unsigned fixed-width values: leaf widths must match,
division or modulo by zero is rejected, and overflow/underflow outside that
leaf width aborts before generation.

The same semantic rule applies in composition because parameter/generic
override values are normalized before the structural plan reaches backend
emission. For example, an external RTL or generated-child instance can pass a
folded aggregate override when the child declaration/default establishes the
expected parameter shape:

```text
(?top:top
  (+constants
    (LANES_A (8'hA5 8'h3C))
    (LANES_B (8'h01 8'h02)))

  (?rtl:core
    (module core)
    (params
      (LANES_SUM (+ LANES_A LANES_B))
      (LANES_MASK (and LANES_A LANES_B))
      (LANES_INV (~ LANES_A))
      (LANES_MATCH (== LANES_A LANES_B)))))
```

The plan records each override as one packed aggregate value, while retaining
its semantic list/record kind and type-shape metadata for validation. A
comparison override records a scalar value because its result is one boolean
parameter/generic literal.

Richer aggregate operators beyond the matching-shape numeric, bitwise, unary
complement, and binary comparison forms remain future work until the specific
operator is defined for the operand aggregate types/shapes and the result can
be validated before generation.

That widening is tracked in [Feature Backlog](14-feature-backlog.md).

Generated `?fsmc` and `?dtc` children now use the same semantic override
surface, but the declaration contract lives in the realized child source's
direct `(+params ...)` block rather than in `.rtlif` metadata:

```text
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
    (<in_data=WIDTH
      (= (out_data> LANES))
    )
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
backend follow-up; the shipped C3 external-RTL, C1 standalone-DT, and C2
generated-FSM composition VHDL tops have no parameter overrides.

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
