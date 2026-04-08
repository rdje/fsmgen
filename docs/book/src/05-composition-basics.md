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
    rstn
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
- `rstn`
- `data_in<8`
- `data_out>8`
- `=status>`

The plain forms are ordinary explicit ports.

The `=name` forms are declared same-name connect-by-name ports. They mean:

- “this top port must bind by the same name”
- not “infer whatever seems convenient”

## Single-Child Passthrough

Generated-child example:

```lisp
(?top:single_child_top
  (?fsmc:child child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
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
    rstn
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
    rstn
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
  rstn
  data_in<8
  txd>
)
```

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
