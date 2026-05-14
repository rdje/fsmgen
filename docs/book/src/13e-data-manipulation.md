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

The emitted `.fsm` uses the normal expression surface: `<<` and `>>` are
supported binary operators through SystemVerilog generation, with `shl` and
`shr` as word aliases. When the shifted value is later used to drive a 1-bit
serial output, select the intended bit explicitly, for example
`(drive mosi tx_byte[7])`; FSMGen does not silently truncate an 8-bit word into
a 1-bit line.

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
and no explicit width option, lowering fails before scheduled `.fsm` emission
instead of emitting a placeholder `WIDTH` expression. An explicit `(width N)`
is an assertion: it may fill missing width evidence, but it must match any
already-known width for the shifted register.

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

When every part width is known, `assemble` derives the target width from the
part-width sum. If the target already has a known width, the sum must match it.
Unknown part widths may still lower to the reviewable concat expression, but
they are not used as target-width evidence.

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
targeted fail-closed diagnostics instead of placeholder slice bounds. Explicit
widths must be positive integers and must not conflict with already known
field widths. When the source word width is known, the sum of field widths
must match it.

```lisp
(state
  (<= (header> (slice packet 15 12)))
  (<= (payload> (slice packet 11 4)))
  (<= (crc> (slice packet 3 0)))
  (-> next_state))
```

### Current Width Evidence Boundary

Before lowering a transaction, ISF builds one private width map from the whole
actor and transaction shape. Interface declarations and actor-owned
`(storage ...)` declarations seed that map, samples inherit known source
widths, explicit `shift_right` and `extract` width options add local evidence,
and `assemble` can infer its target width when all parts are known. This is
type/shape evidence, not cycle-value evidence, so it is not
source-order-sensitive inside the transaction.

Today this evidence is used to avoid `WIDTH`, `HIGH`, and `LOW` placeholders
for accepted migrated data operations. Schedule reports expose positive
integer `width` metadata for inferred scheduler counters and for register
storage whose ISF width evidence is known. They also expose optional `role`
metadata when the lowerer has stable evidence for the storage purpose,
including declared actor-owned storage, sampled aliases, extracted fields,
ordinary data registers, completion pulses, watchdog/latency/repeat counters,
and named-drive request/payload storage.

The planned precedence for this tree is declaration first: interface and
actor-owned storage declarations are hard width facts. Then come explicit
operation-local width options, sampled-alias propagation, structural
derivation from `assemble`/`extract`, and finally existing generated scheduler
storage for counter families. Explicit width options are assertions, not
silent casts: they may fill an unknown width, but they must agree with any
existing width fact for the same name.

Accepted migrated operation families do not emit `WIDTH`, `HIGH`, or `LOW`
placeholders. `extract` fails when field positions cannot be proven.
`shift_right` fails when the shifted register width is missing or
contradictory. `assemble` rejects known target-width mismatches. `shift_left`
does not need separate insertion-position width evidence.

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
