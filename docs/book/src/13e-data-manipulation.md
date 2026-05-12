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
expression.

**Lowering**: `(<- (var expr))` — sequential Q-named assignment.

## `(shift_left reg bit)` — Shift Register (Left)

```lisp
(shift_left rdata sda_in)
```

Shifts `reg` left by 1 and ORs in `bit` at LSB.

**Lowering**: `(<- (reg (| (<< reg 1) bit)))`

```lisp
(state
  (<- (rdata (| (<< rdata 1) sda_in)))
  (-> next_state))
```

**Use case**: I2C/SIPO — capturing serial bits into a parallel register.

## `(shift_right reg bit)` — Shift Register (Right)

```lisp
(shift_right tx_reg msb_data)
```

Shifts `reg` right by 1 and ORs in `bit` at MSB.

**Lowering**: `(<- (reg (| (>> reg 1) (<< bit WIDTH-1))))`

```lisp
(state
  (<- (tx_reg (| (>> tx_reg 1) (<< msb_data 7))))
  (-> next_state))
```

**Use case**: SPI/PISO — shifting out parallel data as serial bits.

## `(assemble (field1 field2 ...) as var)` — Concatenation

```lisp
(assemble (header payload crc) as packet)
```

Concatenates fields into a single variable.

**Lowering**: `(<- (var (concat field1 field2 ...)))`

```lisp
(state
  (<- (packet (concat header payload crc)))
  (-> next_state))
```

**Example — building a SPI frame**:
```lisp
(assemble (cmd addr data) as spi_frame)
;; spi_frame = {cmd[7:0], addr[15:0], data[31:0]} — 56 bits
```

## `(extract word as (field1 field2 ...))` — Bit Slicing

```lisp
(extract packet as (header payload crc))
```

Deconstructs `word` into named fields via slice operations.

**Lowering**: `(<= (field (slice word hi lo)))` for each field.

```lisp
(state
  (<= (header  (slice packet 55 48)))
  (<= (payload (slice packet 47 16)))
  (<= (crc     (slice packet 15 0)))
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
