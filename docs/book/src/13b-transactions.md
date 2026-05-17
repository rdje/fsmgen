# Transactions

A transaction is a behavioral sequence. Every clause produces a specific
`.fsm` state with deterministic timing.

It is useful to think of an ISF transaction as a hardware task: it consumes
cycles, can declare local ports as formal arguments, and activation sites can
pass actual signals through explicit bindings. The hardware caveat is that the
transaction is not a stack-allocated software/SV-task call. It lowers to
static scheduled `.fsm` states, handoff signals, mux selections, and generated
top wiring. Today the task-like port model is shipped for `(ports ...)`
bindings on `do`, `spawn`, and rule `trigger` activation sites. Input bindings
may pass scalar actor-side signals, numeric/exact-width literals, or non-empty
list expressions; output bindings still name scalar writable actor-side
targets. Rule triggers bind transaction inputs only; output bindings require a
caller that waits for completion, such as `do` or the shipped spawn handoff
path. Spawned child
transactions and generated blocking `do` activations support per-instance
parameter overrides through `(params ...)`. Those parameter overrides are
compile-time specialization of a static child instance, not runtime payload
actuals. Parameterized rule triggers now use the same specialization model:
they elaborate generated child activation instances instead of writing mutable
parameter signals into a shared transaction body. Direct `(on ...)` entry
activation is explicitly not a parameter-override site because it is the
transaction's own guard, not a caller-owned generated instance.

Parameter overrides and port bindings must stay separate in authored intent.
Use `(bind (input port expr) ...)` for runtime data/control values that can
change from cycle to cycle. Use `(params (NAME value) ...)` only for static
specialization values on activation forms that explicitly support that surface:
spawned children, blocking `do` generated child activations, and
parameterized rule triggers. Use transaction ports and `(sample ...)` or
activation-site `(bind ...)` entries for runtime-varying values.

```lisp
(do read_word
  (params
    (WIDTH 16))
  (bind
    (input addr (+ base_addr offset))))

(spawn read_word as r0
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))

(trigger read_word
  (params
    (WIDTH 16))
  (bind
    (input addr req_addr)))
```

The lowering contract for this surface is specialization, not assignment. A
parameterized blocking `do` elaborates a generated child activation instance,
applies the override in the generated composition top, starts that instance,
and waits for its `done` handoff. Two activation sites that pass different
parameter values to the same transaction must lower to distinct specialized
transaction instances or cloned scheduled regions. They must not share one
mutable parameter signal written at runtime.

For rule triggers, a parameterized trigger also uses distinct generated
hardware. The generated instance name is
`{rule}_{transaction}_trigger_{ordinal}` so repeated lexical trigger sites do
not collide. The rule still emits the existing one-cycle trigger source and
payload source timing, then a generated trigger handoff DT drives the child
instance start and input handoff ports. Rule-trigger output bindings remain
unsupported because a rule does not await transaction completion.

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

`(on ...)` is the standard activation form. The guard must be a scalar port
name. `(when ...)` can also be used
as activation with identical semantics — useful for expression conditions:
`(when (> counter 5) ...)`.

The only supported inline body clauses inside `(on ...)` are
`(sample port as name)` forms. Other body forms are rejected instead of being
silently ignored.
`(params ...)` is not a legal `(on ...)` body clause. A direct entry guard has
no per-call instance to specialize; transaction-local `params` on that
transaction remain definition defaults. If an author needs a statically
specialized child instance, use a generated activation form (`spawn`,
parameterized blocking `do`, or parameterized rule `trigger`) and pass runtime
data through ports or bindings.

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
- Cycle N: `scl_start=1`, `scl_val=1` asserted. Non-state DT `(-scl)` is
  enabled. The DT's `(<- (scl> scl_val))` schedules output `scl` to become `1`.
- Cycle N+1: `scl` output port = `1`. Next state executes.

**What happens**:
1. `_start` signal for the drive is asserted (=1)
2. Parameter signals are wired to actual values
3. The non-state DT `(-drive_name ...)` is enabled, doing `(<- (port> param_val))`
4. Due to `<-` (flopped), the port output changes NEXT cycle
5. State transitions to next

**Generated .fsm** — Drive DT (once per definition):
```lisp
(-scl
  (<- (scl> scl_val) <scl_start))
```

**Generated .fsm** — Call state (once per call):
```lisp
(i2c_transfer_drive_3
  (= (scl_start 1))               ;; enable the DT
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
| `{name}_start` | 1 | Enables the drive's non-state DT |
| `{name}_{param}` | 1 | One per formal parameter |

## `(sample port as name)` — No State, Piggybacks

**Timing**: 0 extra cycles. Fires on the transition of the enclosing clause.

The sample form is exact: `(sample port as name)`. Both `port` and `name` must
be scalar names. Missing `as`, nested names, and extra operands are rejected
before scheduled `.fsm` emission.

**What happens**:
- Creates a variable. The scheduler infers register if used across phases.
- Inside `(on ...)`: `(<= (name port))` fires when guard triggers.
- Before `(drive ...)` or `(await ...)`: piggybacked onto that state.

**No implicit signals**. The variable `name` is tracked internally.
When a sample is followed by a data operation rather than a drive or await, the
scheduler emits a sample state first so the data operation reads the captured
value.

## `(await port)` — Conditional Stall

```lisp
(await PREADY)                        ;; default watchdog from actor
(await PREADY (watchdog 100))         ;; per-await override
```

**Timing**: 1 to watchdog_limit cycles. Self-looping.

**Cycle-by-cycle**:
- Cycle N: check `port` and the current watchdog Q value
- If `port=1`: transition to next state
- If `port=0`: self-loop, repeat
- If `wd=0`: timeout → error state
- If `wd>0`: schedule the watchdog decrement for the next value

**What happens**:
1. The await DT computes port, timeout, and decrement enables in the same cycle
2. Guard `(<port ...)` fires when port is true
3. Watchdog check `(?wd (=0 ...) (>0 ...))` reads the current watchdog Q value
4. On timeout: request the delayed `done` pulse, set `last_error=1`, return
   to idle

**Generated .fsm**:
```lisp
(apb_transfer_await_3
  (<PREADY
    (-> apb_transfer_drive_4))
  (?apb_transfer_wd
    (=0 (-> apb_transfer_timeout))
    (>0 (-- apb_transfer_wd))))

(apb_transfer_timeout
  (<1 (done> 1))
  (<- (last_error> 1))
  (-> apb_transfer_idle_0))
```

The ordering in the source is not procedural. The `?apb_transfer_wd` selector
tests the current counter value in that cycle; `(-- apb_transfer_wd)` selects
the next D value for the counter only on the `>0` branch. The guard also avoids
describing a zero-to-all-ones next-value underflow for the watchdog. Timeout
normally exits the await state, so that old side effect does not necessarily
escape as a system-level failure, but the scheduled artifact should still not
ask the counter to decrement at zero.

## `(wait N)` — Unconditional Exact-Cycle Delay

```lisp
(wait 3)
```

**Timing**: exactly `N` active transaction cycles for static counts, or exactly
the sampled runtime scalar count for the shipped dynamic subset.

`(wait N)` is different from `(await port)`: it does not check a signal, does
not consume an await watchdog, and does not have an early-exit condition. It
is also different from `(repeat count body...)`: it has no body and does not
iterate any authored actions.

**Cycle-by-cycle**:
- `wait 0`: emit no wait state, consume no active transaction cycle, and
  advance directly to the following transaction clause.
- `wait 1`: occupy one generated wait state for one active cycle, then advance
  on that state's transition to the next transaction clause.
- `wait N`: emit `N` generated wait states and advance through them
  unconditionally, one per cycle for static counts.
- `wait count_signal`: in shipped runtime contexts, bypass on a runtime zero
  count; otherwise snapshot `count_signal` on the predecessor edge and consume
  exactly that many active wait cycles with a generated counter. Consecutive
  top-level runtime waits are allowed; a zero bypass from one wait immediately
  evaluates the next wait's zero/positive split, and the final
  sampled-counter edge of an active wait does the same for the following wait.
  Runtime waits can also follow top-level `await`, `stage`, `repeat` exit
  checks, `await_all`, and `await_any`, where the predecessor's own advance
  condition is combined with the runtime count split.
- `wait (<op> ...)`: use the same runtime zero-bypass and predecessor-edge
  snapshot contract as scalar runtime waits when every referenced signal has
  known width and the expression-width helper derives a positive result width.
  Division and modulo count expressions reject numeric or exact-width literal
  zero divisors before scheduled `.fsm` emission; dynamic scalar divisors are
  accepted but are not proven nonzero yet.

Pending samples immediately before a positive static wait piggyback onto the
first wait state, using the same sample materialization rule as drive/await
piggybacking. Pending samples immediately before `(wait 0)` are preserved and
materialize on the next state-producing clause. Static waits do not introduce
a hidden wait counter; the scheduled `.fsm` review artifact shows the exact
fixed state chain for positive waits. Top-level runtime waits preserve
pending samples with path-specific materialization: the positive path samples
in the first active wait state, then counts greater than one continue in a
generated wait-loop state that does not repeat the sample. The zero path uses
a sample-preserving clone of the following state-producing clause so no hidden
sample-only cycle is inserted and the original following state does not sample
again after a positive wait. This top-level subset is limited to following
states that can carry the zero-count sample without changing timing, including
completion states that preserve the delayed completion pulse and return-to-idle
transition plus independent scalar `set`/`update` states that neither read nor
overwrite a pending sample alias plus independent shift and assemble states;
other successor shapes fail closed until their sample materialization is
specified.
Runtime waits inside `when` bodies and `switch` branches now use the same
one-shot positive sample plus zero-count clone scheme for sample-compatible
successors, including completion, independent scalar setter, independent
shift, and independent assemble successors, while preserving false,
other-case, and fallthrough exits. Setters, shifts, and assemble states that
read or overwrite a pending sample alias remain fail-closed. Pending samples
before `repeat`, `while`, and `until` runtime waits use the same scheme when
the body successor can carry samples; loop-back and loop-exit edges remain
unchanged. Runtime waits whose selected zero-count successor cannot yet carry
samples fail closed.

**Generated .fsm** for `(wait 2)` followed by `(drive tick)`:

```lisp
(main_wait_1
  (-> main_wait_2))

(main_wait_2
  (-> main_drive_3))
```

Successful schedule reports include `transaction_waits[]` entries with
`transaction`, `cycles`, `count_kind`, `count_source`, `entry_state`,
`exit_state`, `counter_signal`, and `counter_width`. Only positive static
waits and accepted runtime waits create report entries. Static waits report
the resolved integer in `cycles` and keep the authored literal, actor constant
name, or actor parameter name in `count_source`; runtime scalar and runtime
expression waits report `cycles` as null and expose the source/counter
metadata instead. Expression waits use `count_kind` `runtime_expression` and
keep the normalized expression in `count_source`. Malformed waits such as
`(wait)`, `(wait 1 2)`, `(wait -1)`, non-scalar or non-integer actor
parameter counts, transaction parameter counts, unknown-width dynamic counts,
unknown-width or malformed expression counts, and unsupported runtime contexts
fail closed. Inline dynamic waits are supported in `when` and
`repeat` bodies, `switch` branches, and `while`/`until` bodies for the
no-pending-sample subset. Pending samples are also supported for `when` bodies
and `switch` branches when the selected zero-count successor can carry samples
without changing timing, including completion, independent scalar setter, and
independent shift and assemble successors. The same pending-sample rule is
also supported in `repeat`, `while`, and `until` bodies for sample-compatible
body successors.
In a `switch`, only the selected branch's runtime wait edge is split; other
cases remain selectable and implicit fallthrough is guarded by the complement
of all explicit case values. In loops, the relevant entry, back-edge, or exit
decision edge is split while the opposite loop branch is preserved. Dynamic
waits whose selected zero-count successor cannot yet carry samples fail closed
with diagnostics that name the rejected body context.

## `(complete port)` — Terminal State

**Timing**: exactly 1 cycle. Returns to idle.

The form is exact: `(complete port)`. The target `port` must be a scalar name.
Missing targets, nested targets, and extra operands are rejected before
scheduled `.fsm` emission.

**What happens**:
1. `(<1 (port 1))` — request a one-cycle delayed completion pulse
2. Transition to idle state
3. In idle: `can_accept=1` is asserted

The current ISF lowering uses the `.fsm` delayed-pulse operator so the
completion port rests low except for the generated one-cycle pulse.

**Generated .fsm**:
```lisp
(apb_transfer_done_5
  (<1 (done> 1))
  (-> apb_transfer_idle_0))
```

## `(repeat N body...)` — Counter + Loop

**Timing**: `N × (body_cycles) + 2` (init + check).

For `(repeat 8 (drive scl 1) (drive scl 0))`:
- Body: 2 cycles per iteration (two drive calls)
- Total: `8 × 2 + 2 = 18` cycles

The form is exact: `(repeat count body...)`, with a scalar non-empty count and
at least one body clause. Malformed missing or nested counts fail before
counter construction.

**What happens**:
1. Init state: `(<= (cnt N))` — load counter via D-input
2. Body states execute each iteration
3. Check state: `(<- (cnt (- cnt 1)))` — decrement via Q-named
4. `(?cnt (=1 → loop) (=0 → exit))` — decision tree

**Implicit signals**:
| Signal | Width | Purpose |
|--------|-------|---------|
| `{tx}_cnt` | inferred | Repeat counter |

Repeat counter width is inferred from the count expression. Decimal literal
counts use the minimum width that can represent the loaded count, named counts
use their known interface or sample-derived width, and unknown forms fall back
to 8 bits. Repeats nested in switch branches declare the same transaction
counter, widened to the largest branch requirement.

The shipped repeat-body clause surface is named drive calls, `await`, `sample`,
`update`, `set`, `shift_left`, `shift_right`, `assemble`, `extract`,
actor-owned bank `store` and `load`, and shipped `wait` clauses. `do`,
`spawn`, `await_all`, `await_any`, `stage`, `contract`, nested `while`, and
nested `until` remain outside the shipped repeat-body subset.

The repeat count is not an elaboration count. It is loaded into a runtime
counter, so a named count may be a dynamic scalar signal when its width is
known. Dynamic counts make latency data-dependent rather than statically fixed;
verification and reports need either a known width-derived bound or an explicit
future bound if tighter proof is required. Dynamic counts also make zero-count
semantics important: a fully general repeat contract must either define
zero-count as "skip the body" or reject zero as an illegal count before the
loop body can run.

If a future repeat body contains `(spawn child as name)`, that loop still
reuses one static child instance named `name`. It does not elaborate one child
per iteration. The scheduler must therefore prove the loop waits for the
instance's fresh completion before a later iteration can start it again, or
reject the construct with a targeted busy/re-entry diagnostic.

## `(while cond body...)` / `(until cond body...)` — Transaction Loops

`(while cond body...)` is a pre-test loop. The scheduler emits an entry
decision state that samples `cond` once before the first possible body
iteration; false exits to the next transaction clause, so zero iterations are
possible. After each body iteration, a generated back-edge decision samples
the same condition again before looping or exiting.

`(until cond body...)` is a body-first loop. The body executes once, then a
generated decision state samples `cond`; true exits and false loops back to
the body. A pre-test "run while not done" loop should be authored as
`(while (! done) body...)` rather than by overloading `until`.

The condition uses the same scalar or list-expression guard surface as
`(when ...)`. It is sampled only in generated decision states. It is not a
continuous guard over a multi-cycle body; once a loop body starts, its states
run according to their own scheduled control flow until they reach the loop
check or an explicit terminal path.

The shipped body surface is the same inline transaction subset used by
`when`/`switch` plus the shipped repeat-body subset: named drives, `await`,
`sample`, `complete`, `repeat`, `update`, `set`, shift/assemble/extract data
operations, actor-owned bank `store`/`load`, nested `when`, and waits. `do`,
`spawn`, `await_all`, `await_any`, `stage`, `contract`, and nested loops remain
deferred until their re-entry, child-lifetime, and report semantics are
specified for loop bodies. Body clauses must be non-empty list forms.

Successful schedule reports expose `transaction_loops[]` entries with the
authored transaction, loop kind, normalized condition, generated decision
states, body start, body states, exit state, and body clause count.

## `(when condition body...)` — Decision State

**Timing**: 1 cycle. If true, body cycles follow. If false, skip to next clause.

The form is exact: `(when condition body...)`, with a scalar or list-form
condition and at least one list-form body clause.

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

The form is exact: `(switch signal (value body...)...)`, with a scalar signal
and one or more list-form branches. Each branch must carry a scalar value and
at least one list-form body clause.

**What happens**:
1. `(?signal (=val1 -> branch1) (=val2 -> branch2) ... (default -> skip))`
2. Each branch body is expanded inline as sequential states
3. Default fallthrough to next clause when no explicit branch predicate matches

**Generated .fsm**:
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> dispatch_drive_1))
    (=1 (-> dispatch_drive_2))
    (default (-> skip))))
```

The generated `.fsm` default selector means the logical negation of the OR of
all explicit sibling branch predicates. For the example above, the skip path is
taken only when neither `opcode == 0` nor `opcode == 1` matched. Authored ISF
can also provide its own fallback branch with `(default body...)` or `(_ body...)`;
when it does, the scheduler does not add an extra implicit fallthrough branch.

## `(set var expr)` / `(update var expr)` / `(shift_left ...)` / `(shift_right ...)` — Data Ops

**Timing**: exactly 1 cycle each.

`(set var expr)` is the canonical explicit scalar setter. It is exact: `var` is
a scalar target and `expr` is one scalar or list expression payload. In a
transaction it lowers as one ordered flopped assignment state. `(update var
expr)` remains supported as the older transaction-local spelling for the same
behavior. Division and modulo inside the RHS reject literal-zero divisor
operands before scheduled `.fsm` emission. Dynamic scalar divisors lower
unchanged; full runtime nonzero proof is still backlog.
Shift operations are also exact scalar forms:
`(shift_left reg bit [(width N)])` and
`(shift_right reg bit [(width N)])`.

**What happens**:
1. `(<- (var expr))` — variable modified, takes effect next cycle (flopped)
2. Expression passes through to `.fsm` directly

**Generated .fsm**:
```lisp
(i2c_transfer_shift_6
  (<- (rdata> (| (<< rdata 1) sda_in)))
  (-> next_state))
```

## `(latency (min N) (max M))` — Verification

**Timing**: no extra states. Adds counter + comparators.

The latency clause accepts one or both `(min N)` and `(max N)` options. `N`
must be a positive integer, each option may appear at most once, and `min`
must be less than or equal to `max` when both are present. A valid explicit
`max` bound drives the generated counter width and max violation check; omitted
bounds use scheduler defaults.

**What happens**:
1. Entry state: `(<- (cc 0))` — reset counter
2. Every active state: `(= (inc 1))` — assert increment
3. Non-state DT: `(<- (cc (+ cc 1)) <inc)` — increment
4. Done state: `(?cc (<N (lerr=1)))` — min violation check
5. Max violation: watchdog timeout

**Implicit signals**: `{tx}_cc`, `{tx}_inc`, `{tx}_lerr` + non-state DT `(-cc_inc)`.

## Timing Summary

| Clause | Cycles | Notes |
|--------|--------|-------|
| `(on port ...)` | 0+ (wait) | Fires when condition met |
| `(drive name args...)` | 1 | One per call |
| `(sample port as name)` | 0 | Piggybacks |
| `(await port)` | 1 to N | Self-looping + watchdog |
| `(complete port)` | 1 | Returns to idle |
| `(repeat N body...)` | N×body+2 | Counter + init + check |
| `(while cond body...)` | 1 + body×N + checks | Pre-test, zero-or-more |
| `(until cond body...)` | body×N + checks | Body-first, one-or-more |
| `(when cond body...)` | 1 + body | Decision + inline body |
| `(switch sig (v b)... (default b))` | 1 + body | Decision + inline branch |
| `(set/update var expr)` | 1 | Flopped assignment |
| `(shift_left reg bit [(width N)])` | 1 | Flopped assignment |
| `(latency (min N) (max M))` | 0 | Verification logic only |
