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
For `shift_right`, known signal widths are used for the inserted MSB position;
an explicit `(width N)` option supplies that width when the register is not
declared elsewhere. Unknown widths still fall back to the placeholder width
expression.

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

Current `extract` lowering emits exact descending slices when the source word
and destination field widths are known. An ordered `(widths N...)` option can
provide field widths for the extract clause when those fields are not declared
elsewhere; the option count must match the field count. Unknown widths keep
placeholder slice bounds for unproven field positions.

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

Spawn lowering writes separate child `.fsm` files, a parent `.fsm` with
per-instance handoff ports, and a generated `<actor>_top.fsm` composition
source when `--outdir DIR` is used. Spawn parameter declarations lower into
child `+params` blocks, and spawn override lists are validated, preserved in
the parent lowerer IR, and applied through generated `?fsmc` `(params ...)`
blocks in the top. The generated top wires parent start outputs, parent done
inputs, child `start`/`done` ports, and named-drive handoff signals through the
existing composition pipeline.

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
