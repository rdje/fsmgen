# Composition Basics

Composition is the `?top` layer that lets FSMGen build one top module from
multiple child blocks.

Current child kinds are:

- `?fsmc` for generated FSM children
- `?dtc` for generated standalone-DT children
- `?rtl` for external RTL children

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

The plain forms are ordinary explicit ports.

The `=name` forms are declared same-name connect-by-name ports. They mean:

- “this top port must bind by the same name”
- not “infer whatever seems convenient”

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
- and using declared same-name forms like `=status>` or `=enable<`.

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
- declared `=name` connect-by-name

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
symbols such as `WIDTH_VALUE`, `mode.BUSY`, or `shared.LANES`; aggregate
overrides are checked against the aggregate shape inferred from the `.rtlif`
default before HDL is emitted. The advanced composition chapter shows the full
pattern.

## Current Boundary

Composition is no longer single-child-only. The shipped live lanes already
cover:

- `C1` single-child passthrough and interface inference
- `C2` explicit-link composition with generated children
- `C3` explicit-link composition with at least one external RTL child
- `C4` declared connect-by-name through `=name`

For the precise normative boundary, keep
[COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) open beside this chapter.

For expressions, structural actuals, concat/repeat sources, inferred carriers,
and type-aware link validation, continue with
[Composition Advanced](06-composition-advanced.md).
