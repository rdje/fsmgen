# Composition Basics

Composition is the `?top` layer that lets FSMGen build one top module from
multiple child blocks.

Current child kinds are:

- `?fsmc` for generated FSM children
- `?dtc` for generated standalone-DT children
- `?rtl` for external RTL children

Other child headers such as `?bogus:child` are rejected as unsupported child
kinds; FSMGen does not reinterpret unknown composition children as raw HDL or
legacy extension hooks.

## Top Root Shape

A composition source uses one `?top:name` root with an
HDL-identifier-compatible top name.

The current active top-root body can contain:

- zero or more declaration sections such as `+constants`, `+enums`, bounded
  `+types`, and bounded `+import`
- zero or one `?ports` block
- one or more child instances
- zero or more explicit `?wiring` wiring blocks
- embedded generated child roots, embedded `?pkg` package roots, or embedded
  `?rtlif` metadata roots as companion source material

Malformed top names, duplicate child declarations, duplicate top ports, several
`?ports` blocks, empty child lists, malformed child entries, malformed port
tokens, and malformed wiring tokens are rejected at the composition boundary
rather than being left for HDL emission.

Duplicate names are rejected before scheduling or wiring inference starts. A
top port name may appear only once in `?ports`, and each realized child
instance name must be unique within the `?top`.

## The Minimal Shape

```text
(?top:top_name
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
)
```

In the narrowest `C1` lane, one child may be enough for the top interface to be
inferred directly when `?ports` is omitted or empty.

Outside inferable single-child lanes, the top boundary must have exactly one
explicit `?ports` block and that block must declare at least one top port.

## Ports

Top ports live in one `?ports` block.

Common forms:

- `clk`
- `reset`
- `rst_n`
- `data_in<8`
- `data_out>8`
- `=status>`

Plain direction tokens are:

- no suffix: one-bit input by default, often used for shared system inputs such
  as `clk` and `rst_n`
- `<` or `<N`: input, optionally with width
- `>` or `>N`: output, optionally with width
- named type or scalar width tokens such as `payload<frame_t` or
  `payload<BYTE_W`

The plain forms are ordinary explicit ports.

Legacy mapping directives such as `/foo/bar/` do not belong inside `?ports`.
Use `?wiring` for explicit connectivity; `?ports` is only for top-port
declarations.

Historical inputs such as `fsm/trial_2.fsm` also used legacy mapping forms like
`/data_o/{tasu_timestamp, tasu_pl_data}/` inside named `?ports` blocks. Those
remain an expected-failure boundary, not an active composition feature.

For readability, `?ports` also accepts verbose declarations. These are aliases
of the compact tokens, not a separate port kind:

```lisp
(?ports:public_io
  (input clk)
  (input rst_n)
  (input data_in (width 8))
  (output result_data (width 8))
)
```

That is equivalent to:

```lisp
(?ports:public_io
  clk
  rst_n
  data_in<8
  result_data>8
)
```

The `(width TOKEN)` attribute accepts the same width tokens as the compact
suffix: positive integer widths, same-scope scalar width symbols, same-scope
type aliases, or direct imported type aliases.

When `TOKEN` names a type, the word `width` is syntax, not a claim that width
and type are the same semantic thing. For example:

```lisp
(?ports:public_io
  packed_out>frame_t
)
```

is equivalent to:

```lisp
(?ports:public_io
  (output packed_out (width frame_t))
)
```

Both forms resolve `frame_t`, use its packed bit width for sizing, and preserve
its declared type contract on the port. The packed width is only the bit count.

Verbose declarations must start with `input` or `output`. Compact tokens must
use HDL-identifier-compatible names and positive widths. FSMGen rejects nested
or wrapper forms in `?ports`, malformed names such as `bad-name>8`, and
non-positive widths such as `data_in<0` at the composition parser boundary.

The declared type contract may also carry signedness, two-state/four-state
intent, aggregate shape, member layout, and type identity. Two ports can
therefore have the same packed width while still being incompatible because
their preserved declared type contracts differ.

The compact `=name` forms and verbose `:same-name` forms are declared
same-name connect-by-name ports:

```lisp
=status>              ;; same as (output status :same-name)
=enable<              ;; same as (input enable :same-name)
=enable               ;; same as (input enable :same-name)
(output status :same-name)
(input enable :same-name)
```

Nullary verbose attributes may be written either as `(attribute)` or
`:attribute`. The canonical concise spelling for declared same-name binding is
`:same-name`; `(same-name)`, `:connect-by-name`, and `(connect-by-name)` are
accepted aliases.

Declared same-name ports mean:

- “this top port must bind by the same name”
- not “infer whatever seems convenient”

Practical rules for declared same-name ports:

- do not use `=clk`, `=rst_n`, or similar system ports; those already use the
  shared system-input contract
- a top-output match is valid only when exactly one compatible child output has
  the same name
- a top-input match is valid when one or more compatible child inputs have the
  same name
- compatibility requires direction, width, and preserved declared type contract
  to agree
- use explicit `?wiring` when you need renaming, remapping, or non-system
  child-to-child wiring

FSMGen rejects declared same-name markers on shared system ports such as
`=clk` or `=rst_n`. Clock and reset ports use the dedicated shared system-input
contract instead of the general connect-by-name path.

## Inference-First Top Boundaries

The preferred authoring model is:

- omit `?ports` when the top boundary can be inferred honestly,
- add `?ports` when you want to disambiguate, rename, constrain, or freeze the
  public interface,
- and fail explicitly when several different public boundaries would all be
  plausible.

In other words, `?ports` is best treated as an interface-control surface, not
as mandatory boilerplate.

That means `?ports` is especially useful for:

- disambiguating multi-child boundaries,
- forcing a stable published interface,
- renaming ports at the top boundary,
- attaching explicit width/type intent when inference is underconstrained,
- and using declared same-name forms like `=status>`, `=enable<`, or
  `(output status :same-name)`.

This is also why the current composition inference work keeps adding more
safe omitted-`?ports` paths: the long-term goal is that authoring a clean
composition should feel lightweight, while still refusing to guess when the
boundary is ambiguous.

## Single-Child Passthrough

Generated-child example:

```lisp
(?top:single_child_top
  (?fsmc:child child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (output_data 8)
  )
  (idle
    (output_data> <= 8'1)
  )
)
```

This works because the top can honestly expose the realized child interface.

When a C1 source authors an explicit `?ports` block, that block must expose
the realized child interface accurately. FSMGen rejects the top before HDL
emission if a child data port is missing from `?ports`, if `?ports` declares a
data port the child does not have, or if an explicitly exposed port disagrees
with the child port's direction or width.

Generated child source roots can be embedded in the same file or resolved from
external `.fsm` sources. Resolution searches repeated `--path DIR` roots, then
`FSMLIB`, then the local directory context. Strict mode requires canonical
`?fsm:name` roots for `?fsmc` children and canonical `?dt:name` roots for
`?dtc` children.

Every child entry must be a proper list whose first item is a real child header
string. Empty child entries, non-string child headers, and dotted-pair child
payloads such as `(?fsmc:child . foo)`, `(?wiring:wiring . foo)`, `(?ports .
foo)`, `(?dtc:child . foo)`, or `(?rtl:uart_tx . foo)` are rejected before
the parser tries to interpret the child kind.

The child form and resolved source root must agree before HDL generation starts.
A `?fsmc` child whose external file is rooted at `?dt:name` is rejected as a
wrong-kind FSM child source and tells the author to use `?dtc` instead. A
`?dtc` child whose external file is rooted at `?fsm:name` is rejected as a
wrong-kind standalone-DT child source and tells the author to use `?fsmc`
instead.

Each `?fsmc` or `?dtc` instance must provide exactly one flat source name. The
only supported nested semantic block on those instances is `(params (NAME
value) ...)`. Other nested blocks, including target-HDL-looking payloads, are
rejected before source realization because generated-child declarations are
structural composition intent, not raw backend text.

Generated children can also be parameterized semantically. Declare the
supported names in the child source with `(+params ...)`, then override those
names on the `?fsmc` or `?dtc` instance:

```lisp
(?top:parameterized_child_top
  (+constants
    (TOP_WIDTH 16)
    (TOP_LANES (8'hA5 8'h3C))
  )
  (?ports:public_io
    clk
    reset
    data_in<16
    data_out>16
  )
  (?fsmc:child child_ctrl_src
    (params
      (WIDTH TOP_WIDTH)
      (LANES TOP_LANES)
    )
  )
)

(?fsm:child_ctrl_src
  (+params
    (WIDTH 8)
    (LANES (8'h00 8'h00))
  )
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (data_in 16)
    (data_out 16)
  )
  (idle
    (data_out> = LANES <data_in=WIDTH)
  )
)
```

Scalar overrides are intentionally width-flexible at the intent layer.

Aggregate overrides must match the list/record shape inferred from the child
parameter default before HDL is emitted.

## Explicit Child-To-Child Wiring

Once you have multiple children, the normal tool is `?wiring`.

```text
(?top:two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.final_data result_data)
  )
)
```

Each list item is one directed link: `(source target)`.

The verbose spelling `(connect source target)` is equivalent and can improve
readability in dense wiring blocks. The older `/source/target/` token remains
accepted as compatibility input, but new examples and generated artifacts use
the list form. In strict mode, `/source/target/` is rejected with a migration
hint because the strict composition surface is the canonical `(source target)`
or `(connect source target)` list form.

List-form wiring entries must be real directed links; a list wrapper around an
old slash token such as `(group /child.out/top_out/)` is rejected instead of
being guessed. Bare arrow-like tokens such as `child.out->top_out` are also
rejected; use `(child.out top_out)`, `(connect child.out top_out)`, or the
legacy `/child.out/top_out/` compatibility token.

Member/item endpoints such as `producer.output_data.extra` require the base
endpoint to carry a declared aggregate type. If the child port is only a scalar
or untyped vector, FSMGen rejects the link and asks for an aggregate `+types`
alias before member or item access is used in composition wiring.

When a generated child FSM omits `+system`, it still has the same direct-root
implicit system defaults as a standalone FSM: `clk` and async active-low
`rst_n`. In a composition top, those implicit child system ports participate in
the shared system-input auto-wiring contract. If the top exposes `clk` and
`rst_n`, generated child instances bind `.clk(clk)` and `.rst_n(rst_n)`
without explicit `?wiring` entries for those system ports; ordinary data links
still belong in `?wiring`.

If a multi-child composition topology needs explicit data routing and no
`?wiring` block is present, FSMGen rejects it after typed composition parsing
and before HDL emission. The scheduler does not guess which child output should
feed a top output or another child input.

Generated standalone-DT children use the same shared system-input convention.
When a `?dtc` child source has explicit `+system` metadata such as
`(clock clk)` and `(areset rst_n)`, those system ports are part of the child
interface and the top binds them by name. A single `?dtc` child can therefore
emit a top instance with `.clk(clk)` and `.rst_n(rst_n)` while data ports such
as `data_in` and `result_data` stay ordinary top/child connections.

## Reusable Standalone-DT Modules

A standalone-DT root is a reusable module-shaped source rooted at `?dt:name`.
The legacy aliases `?mod:name` and `?module:name` are accepted in compatibility
mode, but strict child-source checks require canonical `?dt:name` for `?dtc`
children.

Standalone-DT roots are built from one or more general DT blocks such as
`(-from_a ...)` and `(-from_b ...)`.

Example:

```lisp
(?dt:route_src
  (+size
    (sel 1)
    (a 8)
    (b 8)
    (out 8)
  )
  (-from_a
    (<sel==1'b0
      (out> = a)
    )
  )
  (-from_b
    (<sel==1'b1
      (out> = b)
    )
  )
)
```

Direct `?dt:name` generation reports the reusable-DT structure in
`module_info`:

- `standalone_dt_count`
- `standalone_dt_names`
- `standalone_dt_enable_families`
- `standalone_dt_module_enable_family`
- `standalone_dt_multi_drive_target_count`
- `standalone_dt_multi_drive_targets`

The enable-family metadata names each block-level enable signal and the
module-level group of block enables. For the example above, the block enables
are `from_a_en` and `from_b_en`.

When several standalone-DT blocks drive the same target, FSMGen reports one
grouped multi-drive target family. That family records the target signal,
mux/storage class, contributing DT block names, RHS values, per-DT enable
signals, grouped LHS enable signals, and one bounded assertion metadata object.

SystemVerilog output emits verification-only onehot0 guard assertions for
those grouped standalone-DT multi-drive targets under `` `ifndef SYNTHESIS``.
Verilog output keeps the metadata but does not emit SystemVerilog assertion
syntax.

The same metadata survives `?dtc` realization. A composition top that
instantiates standalone-DT children aggregates those exports through:

- `composition_standalone_dt_child_count`
- `composition_standalone_dt_block_count`
- `composition_standalone_dt_multi_drive_target_count`
- `composition_standalone_dt_children`

Those child exports also live in the top-level `intent_hir`, and they carry
each realized child's forward `intent_hir`, `lowered_rtl_ir`, and structural
interface boundary where those layers exist.

Example:

```text
(?top:dtc_top
  (?ports:public_io
    sel
    data_a<8
    data_b<8
    final_out>8
  )
  (?dtc:router_a route_src)
  (?dtc:router_b route_src)
  (?wiring:wiring
    (sel router_a.sel)
    (data_a router_a.a)
    (data_b router_a.b)
    (router_a.out router_b.a)
    (router_b.out final_out)
  )
)
```

Named `?dtc:name` children may omit the source token and default it to the
instance name. For external files, source lookup follows the same generated
child order: repeated `--path DIR` roots, then `FSMLIB`, then the local source
directory context.

Current boundary: standalone-DT modules do not yet have an authored
enable-control syntax that overrides the implicit block enable, unnamed
`?dt:` roots are not a public contract, and broader reusable-module package or
lookup semantics remain future work.

## Same-Name Convention

There are now several bounded same-name paths:

- single-child top-interface passthrough when `?ports` is omitted or empty
- explicit-link top-port inference when `?wiring` endpoints define the public
  boundary exactly
- undeclared top-input inference when compatible child inputs remain top-facing
- undeclared top-output inference when one unique child output remains top-facing
- plain explicit top ports reusing the same-name convention in explicit-link
  `C2` / `C3` tops
- declared compact `=name` or verbose `:same-name` connect-by-name
- same-name internal carrier inference for one producer and one or more sinks
- explicit top-output re-export of a compatible inferred internal carrier

Simple example:

```text
(?top:single_by_name_top
  (?ports:public_io
    clk
    rst_n
    =enable<
    =output_data>8
  )
  (?fsmc:child child_src)
)
```

This is useful when the top boundary is intentionally the same as the child
boundary.

The shipped rule is direction-asymmetric:

- a same-name top input may fan out to one or more child inputs when every
  child-side candidate is an input and the width/type/declared-type contract
  matches
- a same-name top output must match exactly one child output
- mixed-direction families fail instead of being guessed
- width-equal but declared-type-incompatible families fail instead of being
  flattened to raw vectors

The convention is also local. Explicit `?wiring` owns the exact endpoints it
mentions and overrides same-name convention at those endpoints. The
composition report records those overrides and the common blocked cases, such
as explicit child links preventing undeclared top-interface inference or an
inferred internal carrier staying internal by default.

What this does not mean:

- no broad hidden child-to-child auto-wiring
- no interface-bundle or protocol-group inference
- no priority, merge, or arbitration semantics for same-name conflicts
- no automatic publication of internal carriers as top outputs
- no backend-specific remapping syntax hidden behind `=name`

When the boundary is not obvious, write the link explicitly in `?wiring` or
declare the top port explicitly in `?ports`.

## External RTL Children

External RTL is declared with `?rtl` and described by `.rtlif` metadata.

```text
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    (producer.output_data uart_tx.data_in)
    (uart_tx.txd serial_out)
  )
)
```

With metadata:

```lisp
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
```

The same metadata can be written with verbose port declarations:

```lisp
(?rtlif:uart_tx
  (input clk :clock)
  (input rst_n :reset)
  (input data_in (width 8) :data)
  (output txd :data)
)
```

External RTL metadata can be sidecar `<module>.rtlif` or an embedded
`(?rtlif:module ...)` companion root. Embedded metadata for the requested
module takes precedence over sidecar metadata. Metadata roots are flat port
contracts plus an optional semantic `(params (NAME default_value) ...)` block.
This is the canonical low-level external-RTL interface metadata contract in
the current toolchain. FSMGen does not currently define a separate higher-level
interface-source language above `.rtlif`; future interface abstractions should
be added only when a concrete type, package, shared-datapath, or reusable-module
need cannot be represented honestly by this metadata layer.

Port categories are currently `data`, `clock`, and `reset`; typed clock/reset
ports are system-input roles and output-direction clock/reset tokens are
rejected.

Those category markers are interface roles, not separate HDL data types.

`:clock` marks a clock input that participates in composition's system-clock
auto-wiring, `:reset` marks a reset input that participates in system-reset
auto-wiring, and `:data` marks an ordinary payload/status/control port. The
compact `core_clk:clock` spelling is equivalent to `(input core_clk :clock)`;
`data_in<8:data` is equivalent to `(input data_in (width 8) :data)`; and
`txd>:data` is equivalent to `(output txd :data)`. As with other nullary
verbose attributes, `(clock)`, `(reset)`, and `(data)` are accepted aliases for
`:clock`, `:reset`, and `:data`.

If you need two instances of the same external RTL module, keep one interface
contract and give each `?rtl` child its own instance name:

```lisp
(?top:dual_uart_top
  (?ports:public_io
    clk
    rst_n
    data_a<8
    data_b<8
    tx_a>
    tx_b>
  )
  (?rtl:u_uart_a uart_tx)
  (?rtl:u_uart_b uart_tx)
  (?wiring:wiring
    (data_a u_uart_a.data_in)
    (u_uart_a.txd tx_a)
    (data_b u_uart_b.data_in)
    (u_uart_b.txd tx_b)
  )
)

(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)
```

Here `uart_tx` is the reused RTL module/interface contract, while `u_uart_a`
and `u_uart_b` are the actual child instance names used in links and emitted
HDL.

Each `?rtl` instance must use either the shorthand `(?rtl:module_name)`, the
explicit alias `(?rtl:instance_name module_name)`, or the semantic nested form
`(?rtl:instance_name (module module_name) (params ...))`. Extra flat module
names and unsupported nested blocks are rejected before `.rtlif` metadata is
loaded, because `?rtl` declarations describe an external module contract rather
than raw backend text.

Historical inputs such as `fsm/lte_digital_rf.fsm` used one `?rtl` child to
carry many flat module references. For example, its `?rtl:lte_dif_iosocket`
child currently fails as an expected-failure corpus entry because it names 36
RTL modules in one child declaration. Keep each external RTL child to one
semantic module contract instead.

If an external RTL module is parameterized, keep that contract semantic too:
declare supported parameter/generic names in an optional `.rtlif`
`(params (NAME default_value) ...)` block, then override declared names on the
specific `?rtl` instance. Values may be scalar integer literals, bounded
literal list/record payloads, or resolved composition-top/imported-package
symbols such as `WIDTH_VALUE`, `mode.BUSY`, or `shared.LANES`; `.rtlif`
defaults may also use package-qualified imported symbols such as
`shared.DEFAULT_LANES`. Aggregate overrides are checked against the aggregate
shape inferred from the `.rtlif` default before HDL is emitted. The advanced
composition chapter shows the full pattern.

## Current Boundary

Composition is no longer single-child-only. The shipped live lanes already
cover:

- `C1` single-child passthrough and interface inference
- `C2` explicit-link composition with generated children
- `C3` explicit-link composition with at least one external RTL child
- `C4` declared connect-by-name through compact `=name` or verbose
  `:same-name`
- `C5` diagnostics for duplicate drivers, width mismatches, ambiguous or
  missing connect-by-name matches, unknown endpoints, malformed child/source
  metadata, and blocked inference
- `C6` scoped rejection of older out-of-support composition/template forms

The normative composition boundary now lives in these composition chapters. The
focused [COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) document remains a
maintainer-side scope map while the book continues absorbing the old guide's
user-facing detail.

For expressions, structural actuals, concat/repeat sources, inferred carriers,
and type-aware link validation, continue with
[Composition Advanced](06-composition-advanced.md).
