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
- child-output bit selects like `producer.payload[0]`
- child-output slices like `producer.payload[7:4]`
- bounded concat expressions
- bounded repeat groups

Example:

```lisp
(?toplink:wiring
  /payload_bus[15:8]/byte_sink.data_in/
  /producer.payload[7:4]/consumer.nibble_in/
)
```

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

## Current Boundary

This advanced lane is deliberately rich but still bounded:

- source-side expressions are source-side only
- concat and repeat stay bounded structural forms
- actuals are typed, not raw text escape hatches
- inference is allowed only when one honest answer exists
- explicit mismatches fail before emission

For the exact accepted families, keep
[COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md) beside this chapter.
