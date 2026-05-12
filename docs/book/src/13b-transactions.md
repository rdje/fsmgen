# Transactions

A transaction is a behavioral sequence. Every clause produces a specific
`.fsm` state with deterministic timing.

## How Transactions Become Hardware

```
(transaction name
  clause_1     → state_0  (entry)
  clause_2     → state_1  (1 cycle)
  clause_3     → state_2  (1 cycle or variable)
  ...)
```

Each clause is 1 cycle unless noted. The scheduler links states
in order, adding transitions between them. There is no optimization,
no merging — what you write is what you get.

## `(on port ...)` — Entry/Idle State

**Timing**: 0 active cycles (waits). Fires in 1 cycle when condition is met.

**Cycle-by-cycle**:
- Cycle 0..N: `can_accept=1`, wait for `port=1`
- Cycle N: `port && can_accept` → samples captured, transition to state_1

**What happens**:
1. The implicit `can_accept` signal is asserted (combinational, `1` in idle only)
2. Watchdog counter loaded with `(watchdog_N - 1)`
3. When `port` is true AND `can_accept` is true: samples fire (D-input capture)
4. Transition to first body state

**Generated .fsm**:
```lisp
(apb_transfer_idle_0
  (= (can_accept 1))              ;; implicit ready
  (<= (apb_transfer_wd 65535))    ;; watchdog: load max-1
  (<start                         ;; condition guard
    (<= (addr req_addr))          ;; sample: (sample req_addr as addr)
    (<= (is_write req_write))     ;; sample: (sample req_write as is_write)
    (-> apb_transfer_drive_1)))
```

**Implicit signals created**:
| Signal | Width | Purpose |
|--------|-------|---------|
| `can_accept` | 1 | Ready signal, combinational, `1` only in idle |
| `{tx}_wd` | log2(N) | Watchdog counter, loaded with `limit-1` |

**If no `(await ...)` in transaction**: no watchdog counter created.

## `(drive name args...)` — One State per Call

**Timing**: exactly 1 cycle. The `_start` assertion fires in the current cycle.
The port value changes in the NEXT cycle (flopped).

**Cycle-by-cycle** (for `(drive scl 1)`):
- Cycle N: `scl_start=1`, `scl_val=1` asserted. Comb DT `(-scl)` fires.
  The DT's `(<- (scl scl_val))` schedules `scl` to become `1`.
- Cycle N+1: `scl` output port = `1`. Next state executes.

**What happens**:
1. `_start` signal for the drive is asserted (=1)
2. Parameter signals are wired to actual values
3. The combinational DT `(-drive_name ...)` fires, doing `(<- (port param_val))`
4. Due to `<-` (flopped), the port output changes NEXT cycle
5. State transitions to next

**Generated .fsm** — Drive DT (once per definition):
```lisp
(-scl
  (<- (scl scl_val) <scl_start))
```

**Generated .fsm** — Call state (once per call):
```lisp
(i2c_transfer_drive_3
  (= (scl_start 1))               ;; fire the DT
  (= (scl_val 1))                 ;; wire actual to parameter
  (-> i2c_transfer_drive_4))      ;; next state
```

**Consecutive calls**:
```lisp
(drive scl 1)    ;; cycle N:   state_3
(drive sda 0)    ;; cycle N+1: state_4  (separate state, no merging)
(drive scl 0)    ;; cycle N+2: state_5
```

**Implicit signals per drive definition**:
| Signal | Width | Purpose |
|--------|-------|---------|
| `{name}_start` | 1 | Fires combinational DT |
| `{name}_{param}` | 1 | One per formal parameter |

## `(sample port as name)` — No State, Piggybacks

**Timing**: 0 extra cycles. Fires on the transition of the enclosing clause.

**What happens**:
- Creates a variable. The scheduler infers register if used across phases.
- Inside `(on ...)`: `(<= (name port))` fires when guard triggers.
- Before `(drive ...)` or `(await ...)`: piggybacked onto that state.

**No implicit signals**. The variable `name` is tracked internally.

## `(await port)` — Conditional Stall

**Timing**: 1 to watchdog_limit cycles. Self-looping.

**Cycle-by-cycle**:
- Cycle N: decrement watchdog `(-- wd)`, check `port`
- If `port=1`: transition to next state
- If `port=0`: self-loop, repeat
- If `wd=0`: timeout → error state

**What happens**:
1. Watchdog counter decremented each cycle
2. Guard `(<port ...)` fires when port is true
3. Watchdog check `(?wd (=0 (-> timeout)))` handles timeout
4. On timeout: `done=1`, `last_error=1`, return to idle

**Generated .fsm**:
```lisp
(apb_transfer_await_3
  (-- apb_transfer_wd)
  (<PREADY
    (-> apb_transfer_drive_4))
  (?apb_transfer_wd
    (=0 (-> apb_transfer_timeout))))

(apb_transfer_timeout
  (<- (done 1))
  (<- (last_error 1))
  (-> apb_transfer_idle_0))
```

## `(complete port)` — Terminal State

**Timing**: exactly 1 cycle. Returns to idle.

**What happens**:
1. `(<- (port 1))` — port becomes 1 next cycle (flopped)
2. Transition to idle state
3. In idle: `can_accept=1` (implicit), port defaults to 0 (not re-asserted)
4. Net effect: port is 1 for exactly one cycle

**Generated .fsm**:
```lisp
(apb_transfer_done_5
  (<- (done 1))
  (-> apb_transfer_idle_0))
```

## `(repeat N body...)` — Counter + Loop

**Timing**: `N × (body_cycles) + 2` (init + check).

For `(repeat 8 (drive scl 1) (drive scl 0))`:
- Body: 2 cycles per iteration (two drive calls)
- Total: `8 × 2 + 2 = 18` cycles

**What happens**:
1. Init state: `(<= (cnt N))` — load counter via D-input
2. Body states execute each iteration
3. Check state: `(<- (cnt (- cnt 1)))` — decrement via Q-named
4. `(?cnt (=1 → loop) (=0 → exit))` — decision tree

**Implicit signals**:
| Signal | Width | Purpose |
|--------|-------|---------|
| `{tx}_cnt` | 8 | Repeat counter |

## `(when condition body...)` — Decision State

**Timing**: 1 cycle. If true, body cycles follow. If false, skip to next clause.

**What happens**:
1. `(?condition (=1 → body_start) (=0 → skip_target))`
2. Body states execute if true
3. Skip target is the next top-level clause after the when block

**Generated .fsm**:
```lisp
(test_tx_when_2
  (?mode
    (=1 (-> test_tx_drive_3))
    (=0 (-> test_tx_when_5))))
```

## `(switch signal (val body...)...)` — Multi-Way Decision

**Timing**: 1 cycle. Then matching branch body cycles.

**What happens**:
1. `(?signal (=val1 → branch1) (=val2 → branch2) ... (=0 → skip))`
2. Each branch body is expanded inline as sequential states
3. Default fallthrough to next clause

**Generated .fsm**:
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> dispatch_drive_1))
    (=1 (-> dispatch_drive_2))
    (=0 (-> skip))))
```

## `(update var expr)` / `(shift_left ...)` / `(shift_right ...)` — Data Ops

**Timing**: exactly 1 cycle each.

**What happens**:
1. `(<- (var expr))` — variable modified, takes effect next cycle (flopped)
2. Expression passes through to `.fsm` directly

**Generated .fsm**:
```lisp
(i2c_transfer_shift_6
  (<- (rdata (| (<< rdata 1) sda_in)))
  (-> next_state))
```

## `(latency (min N) (max M))` — Verification

**Timing**: no extra states. Adds counter + comparators.

**What happens**:
1. Entry state: `(<- (cc 0))` — reset counter
2. Every active state: `(= (inc 1))` — assert increment
3. Comb DT: `(<- (cc (+ cc 1)) <inc)` — increment
4. Done state: `(?cc (<N (lerr=1)))` — min violation check
5. Max violation: watchdog timeout

**Implicit signals**: `{tx}_cc`, `{tx}_inc`, `{tx}_lerr` + comb DT `(-cc_inc)`.

## Timing Summary

| Clause | Cycles | Notes |
|--------|--------|-------|
| `(on port ...)` | 0+ (wait) | Fires when condition met |
| `(drive name args...)` | 1 | One per call |
| `(sample port as name)` | 0 | Piggybacks |
| `(await port)` | 1 to N | Self-looping + watchdog |
| `(complete port)` | 1 | Returns to idle |
| `(repeat N body...)` | N×body+2 | Counter + init + check |
| `(when cond body...)` | 1 + body | Decision + inline body |
| `(switch sig (v b)...)` | 1 + body | Decision + inline branch |
| `(update var expr)` | 1 | Flopped assignment |
| `(shift_left reg bit)` | 1 | Flopped assignment |
| `(latency (min N) (max M))` | 0 | Verification logic only |
