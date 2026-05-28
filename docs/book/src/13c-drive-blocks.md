# Drive Blocks

Drives lower to non-state DT blocks that are enabled when their `_start` signal
is asserted. One `(drive ...)` call = one cycle. The DT computes
combinational selector enables; the assignment operators decide the selected
target behavior. Current drive bodies use `<-`, so driven ports update on the
next clock.

Drive definitions are parser-validated before lowering. Each body entry must be
a scalar `(port value)` pair; malformed scalar body entries, nested ports,
missing values, extra operands, and expression-valued drive body assignments
are rejected before the actor shell is returned.

## Simple Drives

```lisp
(drive scl_hi                  ;; definition
  (scl 1))

(drive scl_lo
  (scl 0))

(drive scl_hi)                 ;; call — fires in one cycle
```

**Definition → non-state DT**:
```lisp
(-scl_hi
  (<- (scl> 1) <scl_hi_start))
```

**Call → one state**:
```lisp
(caller_state
  (= (scl_hi_start 1))         ;; assert start -> enable DT
  (-> next_state))
```

## Parameterized Drives

```lisp
(drive (scl val)               ;; formal parameter
  (scl val))

(drive scl 1)                  ;; actual = 1
(drive scl 0)                  ;; actual = 0
```

**Definition → non-state DT with parameter signal**:
```lisp
(-scl
  (<- (scl> scl_val) <scl_start))
```

**Call → one state**:
```lisp
(caller_state
  (= (scl_start 1))            ;; enable DT
  (= (scl_val 1))              ;; wire actual to parameter signal
  (-> next_state))
```

This reduces two drives (`scl_hi`, `scl_lo`) into one parameterized drive.

Known drive calls use exact positional arity. A drive declared with `N`
formal parameters must be called with exactly `N` actual values. Missing
actuals and extra actuals are lowering errors; extra values are not ignored.

This is deliberate: the drive declaration defines fixed hardware roles for its
actuals. Variadic arity belongs only on constructs whose runtime meaning is
list-like or associative and whose lowering contract explicitly says so.

Actual values may be scalar tokens or composed `.fsm` expression forms. This
keeps parameterized drives useful inside realistic fixtures without requiring
temporary variables for simple argument-level composition:

```lisp
(drive (mosi val)
  (mosi val))

(drive mosi (& tx_byte[7] shift_enable))
```

## Multi-Assignment Drives

```lisp
(drive start_condition
  (scl 1)
  (sda_out 0)
  (PENABLE 1))

(drive start_condition)         ;; all three assignments same cycle
```

**DT block**:
```lisp
(-start_condition
  (<- (scl> 1)      <start_condition_start)
  (<- (sda_out> 0)  <start_condition_start)
  (<- (PENABLE> 1)  <start_condition_start))
```

## Cycle Semantics

**One call = one cycle. No automatic merging.**

```lisp
(drive scl 1)          ;; cycle N
(drive sda 0)          ;; cycle N+1
(drive penable 1)      ;; cycle N+2
```

For concurrent execution, put actions in one drive:

```lisp
(drive start_condition
  (scl 1)
  (sda_out 0))
(drive start_condition)   ;; both fire in cycle N
```

## I2C Example

The I2C transfer uses parameterized drives for `scl` and `sda` and
combines them through the protocol's START condition, data clocking,
and STOP condition.

```lisp
(actor i2c_master
  (clock clk)
  (reset rst_n)
  (interface
    (input  start)
    (input  data (width 8))
    (output scl_out)
    (output sda_out)
    (output done))

  (drive (scl val) (scl_out val))
  (drive (sda val) (sda_out val))

  (transaction i2c_transfer
    (on start)
    ;; START condition: SDA low while SCL high
    (drive sda 0) (drive scl 1) (drive scl 0)

    ;; 8 clock pulses for data
    (repeat 8 (drive scl 1) (drive scl 0))

    ;; STOP condition
    (drive scl 0) (drive sda 0) (drive scl 1) (drive sda 1)
    (complete done)))
```

Each `(drive scl X)` or `(drive sda X)` resolves through the
parameterized drive definition above. The transaction body lists the
protocol cycles in source order; the scheduler maps each call onto a
cycle in the lowered `.fsm`.

Each `(drive ...)` is one cycle. The order controls timing.
