# Lowering Reference

Every ISF construct maps to specific `.fsm` patterns.
This chapter shows the exact generated `.fsm` for each construct.

## Actor → Module

```lisp
(actor name
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)
  (interface ...)
  (drive ...)
  (transaction ...))
```

↓

```lisp
(?fsm:name
  (+system (clock clk) (areset rst_n))
  (+size ... inferred signals ...)
  (transaction_states ...)
  (-drive_dt_blocks ...)
  (-can_accept_ctrl ...))
```

Single-domain `(clock-domains ...)` actors lower through the same one-clock
scheduled `.fsm` path using the declared domain clock/reset. Multi-domain
actors currently stop after validated domain partitioning; public lowering
rejects them until the planned `<actor>__domain_<domain>.fsm` artifacts,
generated top wiring, and explicit CDC artifacts are implemented.

## Interface → +size

```lisp
(interface
  (input  start)
  (input  addr (width 32))
  (output done)
  (output rdata (width 32)))
```

↓

```lisp
(+size
  (start 1)
  (addr 32)
  (done 1)
  (rdata 32))
```

Declared interface ports are emitted once. If inferred scheduler storage such
as timeout/error bookkeeping has the same name as an interface port, the
inferred duplicate is suppressed.
When generated scheduled `.fsm` assigns a declared output port, the assignment
LHS carries the normal `.fsm` output marker, for example `done>` or `rdata>`.

## Reset → +system

| ISF | .fsm |
|-----|------|
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst)` |
| `(reset rst_n)` | `(sreset rst_n)` |

Reset name convention: `*_n` or `*_b` suffix infers `active_low`.
Explicit `async`/`active_low`/`active_high` override.

## `(on port ...)` → Entry State

**ISF**:
```lisp
(on start
  (sample req_addr  as addr)
  (sample req_write as is_write))
```

**Generated .fsm**:
```lisp
(apb_transfer_idle_0
  (= (can_accept 1))              ;; implicit: ready signal
  (<- (apb_transfer_wd 65535))    ;; watchdog: load max-1
  (<start                         ;; condition guard
    (<= (addr req_addr))          ;; sample: D-input capture
    (<= (is_write req_write))
    (-> apb_transfer_drive_1)))   ;; transition to first state
```

**Timing**: Idles until `start && can_accept`. Samples fire on the transition.
**Cycles**: 0 active cycles (waiting). 1 cycle for transition.

**Implicit signals**: `can_accept` (1, combinational, asserted in idle).

## `(drive name args...)` -> One State + Non-State DT

**ISF**:
```lisp
(drive (scl val) (scl val))        ;; definition
(drive scl 1)                      ;; call
```

**Generated .fsm**:

Non-state DT block:
```lisp
(-scl
  (<- (scl> scl_val) <scl_start))  ;; flopped: next cycle scl = scl_val
```

Call state:
```lisp
(caller_state
  (= (scl_start 1))               ;; assert DT enable (combinational)
  (= (scl_val 1))                 ;; wire actual to parameter signal
  (-> next_state))                ;; always proceed
```

Actuals can be composed expression forms. For example,
`(drive scl (& bit_a bit_b))` lowers the parameter assignment as
`(= (scl_val (& bit_a bit_b)))`.

**Timing**: The `scl_start` assertion enables the non-state DT in the SAME cycle.
The DT's `<-` assignment takes effect NEXT cycle (flopped).
So `(drive scl 1)` → cycle N: assert start + wire value, cycle N+1: port changes.

**Cycles**: 1 per call. **No automatic merging.**
**Implicit signals**: `{name}_start` (1), `{name}_{param}` (1 per parameter).

## `(sample port as name)` → D-Input Assignment

**ISF**:
```lisp
(sample req_addr as addr)
```

**Generated .fsm**: Piggybacks on the current state — no separate state.
```lisp
(<= (addr req_addr))
```

Inside an `(on ...)` guard, the sample fires when the guard triggers:
```lisp
(<start
  (<= (addr req_addr))
  (-> next_state))
```

In a `(drive ...)` state, samples from preceding `(sample ...)` clauses
appear before the drive's start assertion:
```lisp
(drive_state
  (<= (val trigger))              ;; sample piggybacked
  (= (rdata_start 1))             ;; drive start
  (-> next_state))
```

**Timing**: Captures port value at the moment of transition.
The generated assignment is intentionally `<=`, not `<-`. In FSMGen's `.fsm`
assignment model, `<-` names the flop's Q/output side, while `<=` names the
D-input/next-value side. A sample needs the authored variable name to denote the
sampled next value in the state where the sample is emitted, even though the
registered value is still observed after the clock edge.

That distinction matters especially when a drive follows one or more samples
and the scheduler piggybacks those samples onto the drive state. For example:

```lisp
(sample din as hold)
(drive send hold)
```

can lower the sample and the drive parameter wiring into the same scheduled
state. With `<=`, same-state drive wiring that reads `hold` sees the sampled
D-side value. If the sample used `<-`, `hold` would mean the previous Q/output
value in that state, so the drive could receive stale data unless the scheduler
inserted an extra state. For a flow where the sampled name is consumed only in a
later state, `<-` can look equivalent, but it is not the correct general
contract for ISF sample lowering.

**Implicit signals**: None (sample creates a variable; scheduler infers register if needed).

## `(await port)` → Conditional Stall + Watchdog

**ISF**:
```lisp
(await PREADY)
```

**Generated .fsm**:
```lisp
(apb_transfer_await_3
  (<PREADY                         ;; port guard
    (-> apb_transfer_drive_4))
  (?apb_transfer_wd                ;; timeout check
    (=0 (-> apb_transfer_timeout))
    (>0 (-- apb_transfer_wd))))    ;; watchdog: decrement next value
```

**Timing**: Self-loops until `PREADY=1`. Each loop cycle checks the current
watchdog Q value and, when it is greater than zero, schedules the watchdog
decrement for the next value. The test-node branches are same-cycle selector
equations, not procedural statements executed top to bottom. The decrement is
guarded by `>0`, so the scheduled artifact does not describe a zero watchdog
underflowing to all ones. Timeout normally exits the await state, but the
lowering still keeps the counter's next-value selection aligned with the
current-Q test.
**Cycles**: 1 to watchdog_limit cycles (variable).
**Implicit signals**: `{tx}_wd` (log2(N) bits), plus timeout state.

Timeout state:
```lisp
(apb_transfer_timeout
  (<1 (done> 1))
  (<- (last_error> 1))
  (-> apb_transfer_idle_0))
```

## `(wait N)` -> Static Chain Or Runtime Counter

**ISF**:
```lisp
(wait 2)
```

**Generated .fsm**:
```lisp
(main_wait_1
  (-> main_wait_2))

(main_wait_2
  (-> main_drive_3))
```

The static shipped surface accepts either a non-negative integer literal or an
actor-level constant name. For a resolved `N > 0`, lowering emits exactly `N`
generated `*_wait_*` states, each advancing unconditionally to the next wait
state or the following transaction clause. `(wait 0)` emits no generated state,
consumes no active transaction cycle, and falls through to the following
transaction clause. No hidden wait counter is introduced for this static
literal/constant surface.

If samples are pending before a positive wait, they are emitted in the first
wait state:

```lisp
(main_wait_1
  (<= (addr req_addr))
  (-> main_wait_2))
```

If samples are pending before `(wait 0)`, they stay pending and are emitted on
the next state-producing clause instead.

Schedule reports expose each authored positive static wait through
`transaction_waits[]` with `transaction`, resolved integer `cycles`,
`count_kind`, `count_source`, `entry_state`, `exit_state`, `counter_signal`,
and `counter_width`. Only waits whose resolved count is greater than zero
create report entries. Static waits report `count_kind` as `static`,
`count_source` as the literal or actor constant name, and
`counter_signal`/`counter_width` as null for the fixed-chain lowering.

The shipped symbolic surface is `(wait NAME)`, where `NAME` is an actor-level
constant declared with `(constants (NAME value) ...)`. The constant must
resolve before lowering to a non-negative integer literal. Once resolved, it
uses the same fixed-chain lowering as a literal: a resolved zero emits no wait
state and a resolved positive count emits that many wait states. Actor or
transaction `params` are not wait-count constants because they are overrideable
after scheduled state emission.

The first runtime scalar surface is top-level only:

```lisp
(wait cycles)
```

The count source must be a scalar signal with a known unsigned width. The
predecessor edge is split instead of inserting a decision state:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt cycles) <(& start cycles))
  (-> main_wait_1 <(& start cycles))
  (-> main_drive_2 <(& start (== cycles 0))))

(main_wait_1
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1))))
```

The positive edge snapshots the runtime count into `main_wait_1_cnt` and
enters the generated wait state. The zero edge bypasses that state, so a
runtime zero still consumes no active wait cycle. Once the wait state is
entered, it reads only the sampled counter: a sampled value of `1` exits after
one active cycle, while values greater than `1` decrement and loop until the
counter reaches `1`.

If a top-level runtime wait has pending samples before it, the positive-count
path materializes those samples in the first active wait state. The zero-count
path goes to a sample-preserving clone of the following state, so `count == 0`
still consumes no hidden wait or sample-only cycle:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt cycles) <(& start cycles))
  (-> main_wait_1 <(& start cycles))
  (-> main_wait_1_zero_sample <(& start (== cycles 0))))

(main_wait_1
  (<= (hold din))
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1_loop))))

(main_wait_1_loop
  (-- main_wait_1_cnt)
  (?main_wait_1_cnt
    (=1 (-> main_drive_2)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1_loop))))

(main_wait_1_zero_sample
  (<= (hold din))
  (= (outp_start 1))
  (= (outp_val hold))
  (-> main_done_3))
```

The original `main_drive_2` remains the positive-count successor and does not
carry the sample assignment, preventing a second sample after a positive wait.
The separate `main_wait_1_loop` state handles counts greater than one without
repeating the sample on every loop cycle. If the zero-count successor cannot
carry the pending sample without changing timing, the lowerer rejects the form
until that successor shape has an explicit materialization rule.

Consecutive top-level runtime scalar waits reuse the same split on both the
activation edge and the first wait's final sampled-counter edge. For:

```lisp
(wait first_cycles)
(wait second_cycles)
```

the predecessor of `first_cycles` contains a positive edge for the first wait,
plus a zero edge that immediately evaluates `second_cycles`:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt first_cycles) <(& start first_cycles))
  (<- (main_wait_2_cnt second_cycles) <(& start (== first_cycles 0) second_cycles))
  (-> main_wait_1 <(& start first_cycles))
  (-> main_wait_2 <(& start (== first_cycles 0) second_cycles))
  (-> main_drive_3 <(& start (== first_cycles 0) (== second_cycles 0))))
```

When the first wait has actually been entered, its final sampled-counter edge
performs the same split for the second wait:

```lisp
(main_wait_1
  (-- main_wait_1_cnt)
  (<- (main_wait_2_cnt second_cycles) <(& (== main_wait_1_cnt 1) second_cycles))
  (-> main_wait_2 <(& (== main_wait_1_cnt 1) second_cycles))
  (-> main_drive_3 <(& (== main_wait_1_cnt 1) (== second_cycles 0)))
  (?main_wait_1_cnt
    (>1 (-> main_wait_1))))
```

The second count is sampled only on the edge that enters the second wait. The
first count source is not reread after the first wait starts.

Top-level runtime waits can also follow the shipped predecessor states whose
advance condition is explicit in the scheduler IR:

- After `(await ready)`, the ready edge is split into `ready && cycles` and
  `ready && cycles == 0`; the watchdog timeout transition remains in the await
  state.
- After `(stage name (input ready) (output valid))`, the stage state continues
  driving `valid`, and only the ready edge is split.
- After a top-level `repeat`, the repeat-check exit edge `counter == 0` is
  split, while the loop-back edge remains available.
- After `await_all`, the split condition is the AND of the collected done
  signals plus the runtime count test.
- After `await_any`, the split condition is the OR of the collected done
  signals plus the runtime count test.

For example, a wait after `await_all` lowers the synchronization edge and the
runtime count check into one guard:

```lisp
(parent_await_all_3
  (<- (parent_wait_4_cnt cycles) <(& w0_done w1_done cycles))
  (-> parent_wait_4 <(& w0_done w1_done cycles))
  (-> parent_done_5 <(& w0_done w1_done (== cycles 0))))
```

Runtime wait report entries keep `cycles` null because the exact count is
runtime data. Scalar counts use `count_kind` `runtime_scalar` and name the
source signal in `count_source`. Expression counts use `count_kind`
`runtime_expression` and keep the normalized expression text in
`count_source`. Both forms expose the generated counter through
`counter_signal` and `counter_width`.

A known-width expression count uses the same predecessor-edge snapshot and
zero-bypass contract. For example, `(wait (+ cycles bias))` lowers by loading
the generated counter with the expression value only on the positive-count
path:

```lisp
(main_idle_0
  (<- (main_wait_1_cnt (+ cycles bias)) <(& start (+ cycles bias)))
  (-> main_wait_1 <(& start (+ cycles bias)))
  (-> main_drive_2 <(& start (== (+ cycles bias) 0))))
```

All signal operands referenced by the expression must have known width, and
the expression-width helper must derive a positive result width. Unknown-width
or malformed expressions fail closed before scheduled `.fsm` emission.

Runtime waits in `when` bodies are supported. With no pending sample, if the
wait is the first body state, the branch state carries the counter load and
split transitions:

```lisp
(main_when_1
  (<- (main_wait_2_cnt cycles) <(& cond cycles))
  (-> main_done_4 <(! cond))
  (-> main_wait_2 <(& cond cycles))
  (-> main_drive_3 <(& cond (== cycles 0))))
```

The false edge still skips the entire body. The true/positive edge enters the
wait with a sampled counter, and the true/zero edge bypasses the wait to the
following body state.

If pending samples appear before the `when`-body runtime wait, the true
positive path enters a sample-carrying first wait state and counts greater
than one continue through a no-resample wait loop. The true zero path bypasses
to a sample-preserving clone of the following body state when that state can
carry samples without changing timing. The false path remains an explicit skip
around the sampled body.

Runtime waits in `repeat` bodies are also supported. With no pending sample,
the generated dynamic wait counter is registered with the repeat body's other
counters, and the repeat-check loop-back/exit edges remain unchanged after the
body:

```lisp
(main_repeat_init_1
  (<= (main_cnt 2))
  (<- (main_wait_2_cnt cycles) <cycles)
  (-> main_wait_2 <cycles)
  (-> main_drive_3 <(== cycles 0)))
```

If pending samples appear before the repeat-body runtime wait, the positive
iteration path enters a sample-carrying first wait state and a no-resample
wait loop handles counts greater than one. The zero iteration path bypasses to
a sample-preserving clone of the following body state when that successor can
carry samples. The clone advances to the same repeat-check state as the
original body successor, so repeat loop-back and exit behavior remain
unchanged.

Runtime waits in `switch` branches are supported. With no pending sample, if
one case starts with a runtime wait, the switch state materializes only the
needed branch-entry split for that case. Other explicit cases remain ordinary
selectable branches, and implicit fallthrough is guarded by the complement of
all explicit case predicates:

```lisp
(main_switch_4
  (<- (main_wait_1_cnt cycles) <(& (== sel 0) cycles))
  (-> main_wait_1 <(& (== sel 0) cycles))
  (-> main_drive_2 <(& (== sel 0) (== cycles 0)))
  (?sel
    (=1 (-> main_drive_3))
  )
  (-> main_done_5 <(! (| (== sel 0) (== sel 1)))))
```

The positive selected-case path samples the runtime count and enters the wait.
The zero selected-case path bypasses the wait to the next state in that branch
body. Values not listed by the author take the guarded fallthrough edge.

If pending samples appear before the selected branch's runtime wait, the
positive selected-case path enters a sample-carrying first wait state and a
no-resample wait loop handles counts greater than one. The zero selected-case
path goes to a sample-preserving clone of the following selected-case body
state when that successor can carry samples without changing timing. Other
explicit cases and the implicit fallthrough remain unchanged.

Runtime waits in `while` bodies are supported. With no pending sample, if the
first body state is a runtime wait, both the entry decision and the back-edge
decision split the true branch into positive-count counter load/entry and
zero-count bypass paths. The false branch still exits the loop:

```lisp
(main_while_entry_1
  (<- (main_wait_2_cnt cycles) <(& keep cycles))
  (-> main_wait_2 <(& keep cycles))
  (-> main_drive_3 <(& keep (== cycles 0)))
  (-> main_done_5 <(! keep)))

(main_while_check_4
  (<- (main_wait_2_cnt cycles) <(& keep cycles))
  (-> main_wait_2 <(& keep cycles))
  (-> main_drive_3 <(& keep (== cycles 0)))
  (-> main_done_5 <(! keep)))
```

Runtime waits in `until` bodies are also supported for the no-pending-sample
subset. The first trip through the body uses the predecessor edge that enters
the body. The `until` decision's true path still exits, while the false
back-edge reloads or bypasses the wait for the next iteration:

```lisp
(main_until_check_3
  (-> main_done_4 <stop)
  (<- (main_wait_1_cnt cycles) <(& (! stop) cycles))
  (-> main_wait_1 <(& (! stop) cycles))
  (-> main_drive_2 <(& (! stop) (== cycles 0))))
```

If pending samples appear before the first `while` or `until` body runtime
wait, the positive body path uses the same sample-carrying first wait state and
no-resample wait loop. The zero body path bypasses to a sample-preserving clone
of the following body state when that successor can carry samples. `while`
false exits and `until` true exits remain unchanged, and loop-back edges keep
using the runtime count split on later iterations.

Loop decision states can also split a following runtime wait on loop exit. For
a `while` followed by `(wait cycles)`, the true branch still loops to the
body, while the false exit branch samples or bypasses the following wait.

Runtime waits remain fail-closed when the selected zero-count successor cannot
carry pending samples without changing timing, after predecessor states whose
edge split is not implemented yet, and for expression-valued or
parameter-backed counts.

**Timing**: exactly `N` active transaction cycles, no external condition.
**Cycles**: `N`.

## `(complete port)` → Terminal State

**ISF**:
```lisp
(complete done)
```

**Generated .fsm**:
```lisp
(apb_transfer_done_5
  (<1 (done> 1))                  ;; one-cycle delayed completion pulse
  (-> apb_transfer_idle_0))       ;; return to idle
```

**Timing**: `done` is a one-cycle delayed pulse. The pulse request is made in
the terminal state, and the generated HDL asserts `done` for one cycle at the
`<1` timing point after that request, resting low otherwise. Next cycle: idle.
**Cycles**: 1.

## `(repeat N body...)` → Counter Init + Body + Check

**ISF**:
```lisp
(repeat 8
  (drive scl 1)
  (drive scl 0))
```

`N` must be a scalar non-empty count token, and the body must contain at least
one list-form operation before the scheduler builds the repeat counter and loop
states.

**Generated .fsm**:
```lisp
(i2c_transfer_repeat_init_2
  (<= (i2c_transfer_cnt 8))       ;; load counter (D-input)
  (-> i2c_transfer_drive_3))

(i2c_transfer_drive_3              ;; body: first drive call
  (= (scl_start 1))
  (= (scl_val 1))
  (-> i2c_transfer_drive_4))

(i2c_transfer_drive_4              ;; body: second drive call
  (= (scl_start 1))
  (= (scl_val 0))
  (-> i2c_transfer_repeat_check_5))

(i2c_transfer_repeat_check_5       ;; check + loop
  (<- (i2c_transfer_cnt (- i2c_transfer_cnt 1)))   ;; decrement (Q-named)
  (?i2c_transfer_cnt
    (=1 (-> i2c_transfer_repeat_init_2))           ;; loop back
    (=0 (-> next_state))))                          ;; exit
```

**Timing**: `N × (body_cycles) + 2` (init + check). For `N=8` with 2 drives: `8×2+2=18` cycles.
**Implicit signals**: `{tx}_cnt` (inferred width). Decimal literal counts use
the minimum width that can represent the loaded count, named counts use their
known interface or sample-derived width, and unknown count forms fall back to
8 bits. Switch-nested repeats register the same transaction counter at the
widest required branch width.
Repeat bodies lower named drive calls, awaits, samples, updates, and the
current data operations.

`N` is a counter load value, not a structural replication count. A dynamic
scalar count is therefore compatible with the hardware model when its width is
known, but it makes loop latency runtime-dependent and forces the zero-count
policy to be explicit. The current shipped repeat-body subset does not include
`spawn`; when that is added, a repeated spawn must reactivate the same static
child instance and must not imply dynamic module-instance creation.

## `(while cond body...)` / `(until cond body...)` -> Loop Decision States

**ISF**:
```lisp
(while keep
  (drive tick)
  (wait 1))

(until done_seen
  (drive tick)
  (wait 1))

(complete done)
```

**Generated .fsm shape**:
```lisp
(main_while_entry_1
  (?keep
    (=1 (-> main_drive_2))
    (=0 (-> main_drive_5))))

(main_drive_2
  (= (tick_start 1))
  (-> main_wait_3))

(main_wait_3
  (-> main_while_check_4))

(main_while_check_4
  (?keep
    (=1 (-> main_drive_2))
    (=0 (-> main_drive_5))))

(main_drive_5
  (= (tick_start 1))
  (-> main_wait_6))

(main_wait_6
  (-> main_until_check_7))

(main_until_check_7
  (?done_seen
    (=1 (-> main_done_8))
    (=0 (-> main_drive_5))))
```

`while` emits an entry decision plus a back-edge decision so zero iterations
and repeated condition sampling are both explicit in the scheduled artifact.
`until` emits the body first and checks only after the first body pass. In
both forms, the condition is sampled only in the generated decision state; it
is not a continuous guard over the body.

Schedule reports expose the loop through `transaction_loops[]`, including
`transaction`, `kind`, `condition`, `entry_state`, `decision_states`,
`body_start`, `body_states`, `exit_state`, and `body_clause_count`.

## `(when condition body...)` → Decision State

**ISF**:
```lisp
(when mode
  (drive write_path)
  (drive write_done))
```

**Generated .fsm**:
```lisp
(test_tx_when_2
  (?mode
    (=1 (-> write_body_states))    ;; true: execute body
    (=0 (-> next_top_level))))     ;; false: skip body
```

**Timing**: 1 cycle for the decision, then body cycles (if true), or skip (0 additional).
The body tail exits to the same next state that the false path skips to,
including when the `when` is nested inside a switch branch.
**Implicit signals**: None (uses existing signals in condition).

## `(switch signal (val body...)...)` → Multi-Way Decision

**ISF**:
```lisp
(switch opcode
  (0 (drive read))
  (1 (drive write)
     (drive write_done)))
```

**Generated .fsm**:
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> read_body_states))
    (=1 (-> write_body_states))
    (default (-> skip))))         ;; default: fallthrough
```

**Timing**: 1 cycle for decision, then body cycles of the matching branch.
Branch tails transition to the state after the whole switch; multi-state
branches and repeat-check exits do not fall through into later branch bodies.
The `default` selector is the `.fsm` fallback branch. It is true exactly when
the logical OR of all explicit sibling branch predicates is false. For this
example it means `!(opcode == 0 || opcode == 1)`, not another `opcode == 0`
branch. ISF authors may also write `(default body...)` or `(_ body...)` inside
the switch; that authored branch owns the fallback path and suppresses the
scheduler's implicit fallthrough branch.
**Implicit signals**: None.

## `(update var expr)` / `(shift_left reg bit)` / `(shift_right reg bit [(width N)])` → Sequential State

**ISF**:
```lisp
(shift_left rdata sda_in)
```

**Generated .fsm**:
```lisp
(i2c_transfer_shift_6
  (<- (rdata> (| (<< rdata 1) sda_in)))  ;; Q-named output assignment
  (-> next_state))
```

**Timing**: 1 cycle. Assignment takes effect next cycle.
**Implicit signals**: None (operates on existing variables).
The generated shift expressions are ordinary `.fsm` expressions. Raw `<<` and
`>>`, plus the `shl` and `shr` aliases, pass through the downstream
SystemVerilog path as binary operators rather than schedule-only placeholders.
For `shift_right`, known signal widths are used for the inserted MSB position;
an explicit `(width N)` option supplies that width when the register is not
declared elsewhere. The option is an assertion and must agree with any known
register width. Unknown widths fail closed instead of emitting the placeholder
`WIDTH` expression.

## `(assemble fields... as var)` / `(extract word as fields... [(widths N...)])` → Sequential State

**ISF**:
```lisp
(assemble header payload crc as packet)
```

**Generated .fsm**:
```lisp
(state
  (<- (packet (concat header payload crc)))
  (-> next_state))
```

**Timing**: 1 cycle.
**Implicit signals**: None.

When all `assemble` part widths are known, the target width is derived from
their sum. If the target already has a known width, the sum must match it.
Unknown part widths may still lower as a reviewable concat expression, but
they do not become target-width evidence.

Current `extract` lowering emits exact descending slices when the source word
and destination field widths are known. An ordered `(widths N...)` option can
provide field widths for the extract clause when those fields are not declared
elsewhere; the option count must match the field count. Unknown field widths
or source/field width disagreement fail closed before scheduled `.fsm`
emission, so accepted `extract` source no longer emits placeholder slice
bounds.

## `(store <bank-name> <index> <value>)` / `(load <bank-name> <index> as <target>)` → Scalarized Bank Access

**ISF**:
```lisp
(store data wr_ptr data_in)
(load data rd_ptr as data_out)
```

Here `data` is the declared bank name. Actors may declare more than one bank;
the second item in the action selects the bank being accessed.
`store` is not a general scalar assignment form; it only writes a selected
entry of a declared bank. Use ordinary rule assignments or transaction
`update` for scalar actor-owned storage.
Rule assignments and transaction `update` are separate because they live in
different scheduling regions: rules are actor-level concurrent non-state DTs,
while transaction updates are ordered transaction states.

**Generated .fsm** for a depth-4 bank:
```lisp
(-accepted_push <push_fire
  (<- (data_0 data_in) <(== wr_ptr 0))
  (<- (data_1 data_in) <(== wr_ptr 1))
  (<- (data_2 data_in) <(== wr_ptr 2))
  (<- (data_3 data_in) <(== wr_ptr 3)))

(-accepted_pop <pop_fire
  (<- (data_out> data_0) <(== rd_ptr 0))
  (<- (data_out> data_1) <(== rd_ptr 1))
  (<- (data_out> data_2) <(== rd_ptr 2))
  (<- (data_out> data_3) <(== rd_ptr 3)))
```

**Timing**: read-before-write for same-cycle store/load on one bank. `load`
selects from the current cycle's scalarized bank values. `store` selects the
next value for the matching scalarized bank entry. Write-first or bypass
behavior requires a future explicit option.
**Implicit signals**: none beyond the declared scalarized bank entries.

Malformed access, unknown banks, non-bank storage names, literal indexes
outside fixed depth, and known width mismatches fail before scheduled `.fsm`
is accepted. Successful schedule reports include bounded `bank_accesses`
metadata for downstream tools.

## `(latency (min N) (max M))` → Verification Logic

**ISF**:
```lisp
(latency (min 2) (max 16))
```

**Generated .fsm** — adds to entry state:
```lisp
(apb_transfer_idle_0
  (<- (apb_transfer_cc 0))        ;; reset counter
  ...)
```

Adds to every active state (not idle/done):
```lisp
(= (apb_transfer_inc 1))          ;; assert increment
```

Adds non-state DT:
```lisp
(-apb_transfer_cc_inc
  (<- (apb_transfer_cc (+ apb_transfer_cc 1)) <apb_transfer_inc))
```

Adds to done state:
```lisp
(?apb_transfer_cc
  (<2 (= (apb_transfer_lerr 1)))) ;; min violation check
```

**Timing**: Counter increments each active cycle. Min violation = error if done too early.
Max violation via watchdog timeout (if no `(await ...)` in transaction).
**Implicit signals**: `{tx}_cc` (inferred), `{tx}_inc` (1), `{tx}_lerr` (1).

## `(do child)` → Handshake

Local blocking `do` lowers by rewiring the child transaction inside the parent
scheduled module.

**In parent**:
```lisp
(parent_do_1
  (= (child_start 1))             ;; assert child start
  (<child_done                    ;; await done
    (-> parent_do_2)))
```

**In child (rewired)**:
```lisp
(child_idle_0                     ;; was: (<original_port ...)
  (<child_start                   ;; now: watches parent's start
    (-> child_drive_0)))

(child_done_5                     ;; terminal: pulses done
  (<1 (done> 1))
  (<1 (child_done 1))             ;; pulse parent-visible child completion
  (-> child_idle_0))
```

**Implicit signals**: `{child}_start` (1), `{child}_done` (1).
The internal `{child}_done` handoff is pulse-shaped for the same reason as the
public completion output: a parent may call the same child again, and a sticky
done bit would let the next `(do child)` observe an old completion.

Parameterized blocking `do` lowers through a generated child activation
instance instead of a local child handshake:

```lisp
(do child
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)
    (output data resp)))
```

Representative parent `.fsm`:

```lisp
(parent_do_1
  (= (parent_child_do_0_start> 1))
  (<parent_child_do_0_done
    (-> parent_next_2)))

(-parent_child_do_0_port_bindings
  (= (parent_child_do_0_addr> req_addr))
  (= (resp> parent_child_do_0_data) <parent_child_do_0_done))
```

Representative generated top `.fsm`:

```lisp
(?fsmc:parent_child_do_0 child
  (params
    (WIDTH 16)))
```

The generated instance name is `{parent}_{child}_do_{ordinal}`. Input bindings
are parent-owned handoff assignments; the RHS may be a scalar signal,
numeric/exact-width literal, or non-empty list expression. Output bindings are
guarded by the generated instance's `done` pulse and keep scalar actor-side
targets. The generated top applies static parameter overrides and wires only
the explicit activation handoffs; unlike spawn, it does not auto-fanout
unrelated public actor inputs into the child instance.

Spawn lowering writes separate child `.fsm` files, a parent `.fsm` with
per-instance handoff ports, and a generated `<actor>_top.fsm` composition
source when `--outdir DIR` is used. Spawn and parameterized `do` parameter
declarations lower into child `+params` blocks, and override lists are
validated, preserved in the parent lowerer IR, and applied through generated
`?fsmc` `(params ...)` blocks in the top. The generated top wires parent start
outputs, parent done inputs, child `start`/`done` ports, explicit port-binding
handoffs, and named-drive handoff signals through the existing composition
pipeline.

The generated child instance is static HDL. A spawn state activates that
instance through its start path; the child terminal state returns to the
start-gated idle state and waits for a later start. Reaching the same spawn
site again reuses the same instance. This is the required interpretation for
future spawn-in-repeat support as well.

## Complete Example — APB Transfer

All constructs together:

```lisp
(transaction apb_transfer
  (on start (sample req_addr as addr) (sample req_write as is_write)
            (sample req_wdata as wdata))
  (drive setup_phase)
  (drive access_phase)
  (await PREADY)
  (sample PRDATA as rdata) (sample PSLVERR as slverr)
  (drive done_phase)
  (complete done)
  (latency (min 2) (max 16)))
```

Generates 7 state DTs + non-state DTs:

```
idle_0          ← (on start ...) : guards on start, samples, can_accept
drive_1         ← (drive setup_phase)
drive_2         ← (drive access_phase)
await_3         ← (await PREADY) + watchdog
drive_4         ← (drive done_phase) with samples
done_5          ← (complete done): request one-cycle done pulse, return to idle
timeout         ← watchdog timeout
cc_inc_dt       ← latency cycle counter DT
```

In the APB requester fixture, `done_phase` owns protocol cleanup and sampled
response publication; it does not drive transaction `done`. The completion
signal is owned by `(complete done)`, because `done` is the scheduler-visible
transaction completion event rather than an APB bus signal.

Total: 7 states. Each `(drive ...)` is one state. `(await ...)` is one state.
`(sample ...)` piggybacks — no extra state.

## Phases and Stages

### Phases

```lisp
(phase setup (outputs valid rdata) (next finish))
```

Phases are named markers within a transaction. Currently lowered as
pass-through sequential states. The `(outputs ...)` declaration is
parsed but does not generate drive assignments. Phase names must be scalar,
and phase body entries must be list forms before an actor shell is returned.

**Status**: Parsed, lowered as pass-through. Future: jump targets,
conditional entry points. Needs more design discussion.

### Stages

```lisp
(stage pass_through (input ready) (output valid) (latency (max 3))
  (compute (valid ready)))
```

Pipeline stages with implicit valid/ready handshake. Stage names must be scalar,
and stage body entries must be list forms before an actor shell is returned.
The first shipped transaction-stage subset is intentionally smaller than the
historical free-form examples: a top-level transaction clause with one ready
input and one valid output.

Actor-level `(phase ...)` and `(stage ...)` metadata uses the same scalar-name
and list-body structural boundary, is carried in the parser actor shell for
downstream consumers, and is not semantically enforced by the scheduler yet.
That actor-level metadata is not copied into the scheduling IR, schedule JSON,
generated `.fsm`, generated composition top, or HDL today.

```lisp
(stage accept
  (input ready)
  (output valid))
```

That stage lowers to one transaction state. While the state is active, `valid`
is driven combinationally high with `=`, and the state advances only when
`ready` is true in the same cycle. If `ready` is false, the FSM remains in the
stage state and keeps `valid` asserted. Pending samples immediately before the
stage materialize before the stage so a stall does not resample every cycle.
Schedule reports expose this shipped subset through `transaction_stages`
entries with the authored transaction/stage names, `kind =
ready_valid_barrier`, generated state, ready input, and valid output.
Nested stages, stage-local `(latency ...)`, `(compute ...)`, embedded
transaction actions, multiple ready/valid endpoints, registered-valid variants,
and skid-buffer behavior remain separate backlog features until their
generated-state and runtime semantics are explicit.

**Future**: Grow toward richer pipeline registers only after the shipped
ready/valid barrier report contract is complete.

### Contracts

```lisp
(contract (always request -> eventually[1..8] grant))
```

Historical/free-form temporal assertions like that remain deferred. The first
shipped contract model is a transaction-local bounded eventual check:

```lisp
(contract response_seen
  (eventually done (within 8)))
```

When the transaction reaches the contract clause, lowering emits one arm state
that asserts an internal combinational arm request for that cycle. The checked
window starts on the next cycle and lasts for the specified positive integer
number of cycles. If `done` is seen before the window expires, the obligation
clears. If the window expires first, or if the same contract is armed again
while an obligation is still pending, a generated sticky fail bit is set until
actor reset.

The reviewable artifact is not SVA-only. The scheduled `.fsm` contains one arm
state plus an always-on monitor DT with pending, age, and fail storage. The
monitor DT is the source of truth; schedule reports classify it as
`temporal_contract_monitor` and report pending/fail as registers and age as a
counter. They also expose bounded `temporal_contracts` entries with the public
trigger state, observed signal, cycle bound, generated pending/counter/fail
signal names, reset policy, overlap policy, and assertion projection status.
Generated SystemVerilog assertion text from the fail bit remains deferred;
the current assertion projection status is `none`. Unsupported bodies and
nested contracts fail closed. Global
`always` implication forms, min/max windows, dynamic bounds, same-cycle
windows, expression operands, and multiple outstanding obligations remain
deferred.

For a three-cycle window, the scheduled artifact has this shape:

```lisp
(main_contract_1
  (= (main_contract_1_arm 1))
  (-> main_done_2))

(-main_contract_1_monitor
  (<- (main_contract_1_pending 1)
      <(& main_contract_1_arm (! main_contract_1_pending)))
  (<- (main_contract_1_pending 0)
      <(| (& main_contract_1_pending done)
          (& main_contract_1_pending (! done) (== main_contract_1_age 2))))
  (<- (main_contract_1_age 0)
      <(& main_contract_1_arm (! main_contract_1_pending)))
  (<- (main_contract_1_age (+ main_contract_1_age 1))
      <(& main_contract_1_pending (! done) (! (== main_contract_1_age 2))))
  (<- (main_contract_1_fail 1)
      <(| (& main_contract_1_arm main_contract_1_pending)
          (& main_contract_1_pending (! done) (== main_contract_1_age 2)))))
```
