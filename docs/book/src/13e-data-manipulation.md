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

Division and modulo RHS expressions also fail closed when a divisor operand is
a numeric/exact-width literal zero or an actor-level constant that resolves to
zero, including nested expressions such as
`(update out (+ mask (% numerator 8'd0)))` or `(set out (/ numerator ZERO))`.

Nonzero literal divisors, nonzero actor-constant divisors, and dynamic scalar
divisors are preserved in the scheduled `.fsm`; FSMGen does not yet prove
arbitrary dynamic divisors nonzero.

**Lowering**: `(<- (var expr))` — sequential Q-named assignment.

## `(shift_left reg bit [(width N)])` — Shift Register (Left)

```lisp
(shift_left rdata sda_in)
(shift_left rdata sda_in (width 8))
```

Shifts `reg` left by 1 and ORs in `bit` at LSB.

The form is exact: `(shift_left reg bit)` or
`(shift_left reg bit (width N))`, with scalar `reg`, scalar `bit`, and a
positive integer width when the option is present.

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

An explicit `(width N)` is transaction-local width evidence for `reg`, not a
cast or resize. It may fill a missing width fact for later operations such as
`shift_right` and for schedule-report storage metadata, but it must match any
already-known width for the shifted register. Plain `(shift_left reg bit)`
remains accepted without width evidence because the left-shift expression does
not need a computed MSB insertion position.

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
part-width sum. If exactly one part width is missing and the target width plus
all sibling part widths are known, FSMGen infers the missing part width as the
positive remainder. That inferred part width remains available as
transaction-local evidence for later data operations, such as a following
`shift_right` on the assembled part. If the target already has a known width,
the final part-width sum must match it. A zero or negative inferred remainder
fails closed. Two or more unknown part widths may still lower to the
reviewable concat expression, but they are not used as width evidence.

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
from an exact descending slice. If exactly one destination field width is
missing and the source word plus every sibling field has known positive width,
FSMGen infers the missing field width as the positive remainder. That inferred
width remains available as transaction-local evidence for later data
operations, such as a following `shift_right` on the extracted field. Two or
more unknown field widths remain ambiguous and fail closed instead of
placeholder slice bounds. Explicit widths must be positive integers and must
not conflict with already known field widths. When the source word width is
known, the sum of field widths must match it; a zero or negative inferred
remainder fails closed.

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
widths, explicit `shift_left`, `shift_right`, and `extract` width options add
local evidence, and `assemble` can infer its target width when all parts are
known or infer one missing part width from a known target and known siblings.

This is
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
placeholders. `extract` fails when field positions cannot be proven after the
single-missing-field inference rule.

`shift_right` fails when the shifted register width is missing or
contradictory. `shift_left` accepts optional width evidence and rejects
contradictory explicit widths while still accepting widthless shifts.

`assemble` rejects known target-width mismatches and non-positive single-part
inferred remainders.

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
