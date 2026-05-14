# Data Manipulation

ISF provides abstract data manipulation constructs that the scheduler
lowers to appropriate `.fsm` expressions.

## `(update var expr)` — Variable Modification

```lisp
(update counter (- counter 1))
(update status BUSY)
(update rdata (| (<< rdata 1) bit_in))
```

General-purpose variable assignment. The expression is any `.fsm`-compatible
expression, supplied as one scalar or list expression payload. The form is
exact: `(update var expr)`, with scalar `var`. Missing expressions, nested
targets, and extra operands are rejected before scheduled `.fsm` emission.

**Lowering**: `(<- (var expr))` — sequential Q-named assignment.

## `(shift_left reg bit)` — Shift Register (Left)

```lisp
(shift_left rdata sda_in)
```

Shifts `reg` left by 1 and ORs in `bit` at LSB.
The form is exact: `(shift_left reg bit)`, with scalar `reg` and scalar `bit`.

**Lowering**: `(<- (reg (| (<< reg 1) bit)))`, or `reg>` when `reg` is a
declared output port.

```lisp
(state
  (<- (rdata> (| (<< rdata 1) sda_in)))
  (-> next_state))
```

**Use case**: I2C/SIPO — capturing serial bits into a parallel register.

## `(shift_right reg bit [(width N)])` — Shift Register (Right)

```lisp
(shift_right tx_reg msb_data)
(shift_right tx_reg msb_data (width 8))
```

Shifts `reg` right by 1 and ORs in `bit` at MSB.
The form is exact: `(shift_right reg bit)` or
`(shift_right reg bit (width N))`, with scalar `reg`, scalar `bit`, and
positive integer width when the option is present.

**Lowering**: `(<- (reg (| (>> reg 1) (<< bit width-1))))`

```lisp
(state
  (<- (tx_reg (| (>> tx_reg 1) (<< msb_data 7))))
  (-> next_state))
```

Known interface, sampled-source, assemble-inferred, and explicit `(width N)`
widths use a concrete insert position. If the shifted value has no known width
and no explicit width option, the current implementation falls back to the
placeholder `WIDTH` expression.

## `(assemble field1 field2 ... as var)` — Concatenation

```lisp
(assemble header payload crc as packet)
```

Concatenates fields into a single variable.
The form is exact: `(assemble part... as var)`, with one or more scalar parts
and scalar target `var`.

**Lowering**: `(<- (var (concat field1 field2 ...)))`

```lisp
(state
  (<- (packet (concat header payload crc)))
  (-> next_state))
```

**Example — building a SPI frame**:
```lisp
(assemble cmd addr data as spi_frame)
```

## `(extract word as field1 field2 ... [(widths N...)])` — Field Extraction

```lisp
(extract packet as header payload crc)
(extract packet as header payload crc (widths 4 8 4))
```

Deconstructs `word` into named fields. The form is exact:
`(extract word as field... [(widths N...)])`, with one scalar source word and
one or more scalar destination fields. The optional `(widths N...)` payload
must contain one positive integer width per field.

**Current lowering**: one extraction state is emitted. When the source word and
destination fields have known widths, or when the extract clause supplies an
ordered `(widths N...)` list matching the field count, each field is assigned
from an exact descending slice. If a width is unknown, the scheduler preserves
placeholder slice bounds for the unproven field positions. Explicit widths must
be positive integers and must not conflict with already known field widths.

```lisp
(state
  (<= (header> (slice packet 15 12)))
  (<= (payload> (slice packet 11 4)))
  (<= (crc> (slice packet 3 0)))
  (-> next_state))
```

## I2C Shift Register — Complete Example

```lisp
(transaction i2c_transfer
  (on start ...)
  ;; Capture 8 bits via shift register
  (repeat 8
    (drive scl 1)
    (shift_left rdata sda_in)
    (drive scl 0))
  (complete done))
```

Each cycle: SCL high → sample `sda_in` into `rdata` LSB → SCL low.
After 8 cycles: `rdata` contains the full byte.
