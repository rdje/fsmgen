# Transactions

A transaction is the core behavioral unit. The scheduler lowers it to
an explicit FSM state sequence.

## Anatomy

```lisp
(transaction apb_transfer
  (on start                              ;; activation
    (sample req_addr as addr))
  (drive setup_phase)                    ;; combinational outputs
  (await PREADY)                         ;; conditional stall
  (complete done)                        ;; completion
  (latency (min 2) (max 16)))           ;; timing constraint
```

## Entry: `(on ...)`

```lisp
(on start                                    ;; port name
  (sample req_addr  as addr)                 ;; capture inputs
  (sample req_write as is_write))

(on (& start trigger)                        ;; expression
  (sample data as val))

(on (> counter 5)                            ;; comparison
  (drive reset_phase))
```

**Semantics**: Fires when port/expression is true AND `can_accept` is true.

**Lowering**:
```lisp
(apb_transfer_idle_0
  (= (can_accept 1))
  (<start
    (<= (addr req_addr))          ;; samples inside guard
    (<= (is_write req_write))
    (-> apb_transfer_drive_1)))
```

## Sample: `(sample port as name)`

```lisp
(sample req_addr  as addr)        ;; capture req_addr into variable addr
(sample PREADY   as was_ready)    ;; mid-transaction sample
(sample HRDATA   as beat_data)    ;; inside repeat
```

Creates a variable. Scheduler infers register if used across phases.

**Lowering**: `(<= (name port))` — D-input assignment.

## Complete: `(complete port)`

```lisp
(complete done)
```

Pulses `port` for one cycle then returns to idle.

**Lowering**:
```lisp
(apb_transfer_done_5
  (= (done> 1))
  (-> apb_transfer_idle_0))
```

## Await: `(await port)`

```lisp
(await PREADY)                    ;; stall until PREADY = 1
```

Stalls until `port` is true. Watchdog auto-injected.

**Lowering**:
```lisp
(apb_transfer_await_3
  (-- apb_transfer_wd)            ;; decrement watchdog
  (<PREADY                        ;; port guard
    (-> apb_transfer_drive_4))
  (?apb_transfer_wd               ;; timeout check
    (=0 (-> apb_transfer_timeout))))
```

**Timeout state**:
```lisp
(apb_transfer_timeout
  (= (done> 1))
  (= (last_error> 1))
  (-> apb_transfer_idle_0))
```

## Repeat: `(repeat N body...)`

```lisp
(repeat 8
  (drive scl 1)
  (drive scl 0))
```

Loops `N` times. `N` can be a literal or a bound name.

**Example — I2C clock toggling**:
```lisp
(repeat 8
  (drive scl 1)          ;; SCL high
  (drive scl 0))         ;; SCL low — 8 clock pulses
```

**Lowering**:
```lisp
(i2c_transfer_repeat_init_2       ;; load counter
  (<= (i2c_transfer_cnt beats))
  (-> i2c_transfer_drive_3))

(i2c_transfer_drive_3             ;; body: scl=1
  (= (scl_start 1))
  (= (scl_val 1))
  (-> i2c_transfer_drive_4))

(i2c_transfer_drive_4             ;; body: scl=0
  (= (scl_start 1))
  (= (scl_val 0))
  (-> i2c_transfer_repeat_check_5))

(i2c_transfer_repeat_check_5      ;; check + loop
  (<- (i2c_transfer_cnt (- i2c_transfer_cnt 1)))
  (?i2c_transfer_cnt
    (=1 (-> i2c_transfer_repeat_init_2))   ;; loop back
    (=0 (-> next_state))))                  ;; exit
```

## Latency: `(latency (min N) (max M))`

```lisp
(latency (min 2) (max 16))
```

Timing constraint — compile-time check enforced with synthesizable
verification logic.

**Lowering**: Injects `cycle_count` counter, `inc` enable, and
`latency_error` flag:

```
Entry state:
  (<- (cycle_count 0))           ;; reset counter

Active states:
  (= (inc 1))                    ;; assert increment

Combinational DT:
  (-cc_inc
    (<- (cycle_count (+ cycle_count 1)) <inc))

Done state:
  (?cycle_count
    (<2 (latency_error = 1)))    ;; min violation

Max violation: watchdog timeout.
```

## Update: `(update var expr)`

```lisp
(update rdata (| (<< rdata 1) sda_in))    ;; shift in a bit
(update counter (- counter 1))             ;; decrement
(update status BUSY)                       ;; set to constant
```

General variable modification. Expression is any `.fsm`-compatible expression.

**Lowering**: `(<- (var expr))` — sequential Q-named assignment.

```lisp
(i2c_transfer_update_5
  (<- (rdata (| (<< rdata 1) sda_in)))
  (-> next_state))
```

## Complete Example — APB Transfer

```lisp
(transaction apb_transfer
  (on start
    (sample req_addr  as addr)
    (sample req_write as is_write)
    (sample req_wdata as wdata))
  (drive setup_phase)
  (drive access_phase)
  (await PREADY)
  (sample PRDATA  as rdata)
  (sample PSLVERR as slverr)
  (drive done_phase)
  (complete done)
  (latency (min 2) (max 16)))
```

**Generated FSM states**:
```
idle → drive(setup) → drive(access) → await(PREADY)
     → drive(done) → done → idle
     7 states total
```
