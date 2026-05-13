# Drive Blocks

Drives lower to non-state DT blocks that are enabled when their `_start` signal
is asserted. One `(drive ...)` call = one cycle. The assignment operators in
the DT decide timing: current drive bodies use `<-`, so driven ports update on
the next clock.

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
  (<- (scl 1) <scl_hi_start))
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
  (<- (scl scl_val) <scl_start))
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
  (<- (scl 1)       <start_condition_start)
  (<- (sda_out 0)   <start_condition_start)
  (<- (PENABLE 1)   <start_condition_start))
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

```lisp
(actor i2c_master
  ...
  (drive (scl val) (scl val))
  (drive (sda val) (sda_out val))

  (transaction i2c_transfer
    (on start ...)
    ;; START condition: SDA low while SCL high
    (drive sda 0) (drive scl 1) (drive scl 0)

    ;; 8 clock pulses for data
    (repeat 8 (drive scl 1) (drive scl 0))

    ;; STOP condition
    (drive scl 0) (drive sda 0) (drive scl 1) (drive sda 1)
    (complete done)))
```

Each `(drive ...)` is one cycle. The order controls timing.
