# Composition Basics

Composition is the `?top` layer that lets FSMGen build one top module from
multiple child blocks.

Current child kinds are:

- `?fsmc` for generated FSM children
- `?dtc` for generated standalone-DT children
- `?rtl` for external RTL children

## Top Root Shape

A composition source uses one `?top:name` root with an
HDL-identifier-compatible top name.

The current active top-root body can contain:

- zero or more declaration sections such as `+constants`, `+enums`, bounded
  `+types`, and bounded `+import`
- zero or one `?ports` block
- one or more child instances
- zero or more explicit `?toplink` wiring blocks
- embedded generated child roots, embedded `?pkg` package roots, or embedded
  `?rtlif` metadata roots as companion source material

Malformed top names, duplicate child declarations, duplicate top ports, several
`?ports` blocks, empty child lists, malformed child entries, malformed port
tokens, and malformed toplink tokens are rejected at the composition boundary
rather than being left for HDL emission.

## The Minimal Shape

```lisp
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
- use explicit `?toplink` when you need renaming, remapping, or non-system
  child-to-child wiring

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

Generated child source roots can be embedded in the same file or resolved from
external `.fsm` sources. Resolution searches repeated `--path DIR` roots, then
`FSMLIB`, then the local directory context. Strict mode requires canonical
`?fsm:name` roots for `?fsmc` children and canonical `?dt:name` roots for
`?dtc` children.

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

Once you have multiple children, the normal tool is `?toplink`.

```lisp
(?top:two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)
```

Plain port-to-port links are still the easiest starting point.

## Same-Name Convention

There are now several bounded same-name paths:

- undeclared top-input inference when compatible child inputs remain top-facing
- undeclared top-output inference when one unique child output remains top-facing
- plain explicit top ports reusing the same-name convention
- declared compact `=name` or verbose `:same-name` connect-by-name

Simple example:

```lisp
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

## External RTL Children

External RTL is declared with `?rtl` and described by `.rtlif` metadata.

```lisp
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
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

External RTL metadata can be sidecar `<module>.rtlif` or an embedded
`(?rtlif:module ...)` companion root. Embedded metadata for the requested
module takes precedence over sidecar metadata. Metadata roots are flat port
contracts plus an optional semantic `(params (NAME default_value) ...)` block.
Port categories are currently `data`, `clock`, and `reset`; typed clock/reset
ports are system-input roles and output-direction clock/reset tokens are
rejected.

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
  (?toplink:wiring
    /data_a/u_uart_a.data_in/
    /u_uart_a.txd/tx_a/
    /data_b/u_uart_b.data_in/
    /u_uart_b.txd/tx_b/
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
