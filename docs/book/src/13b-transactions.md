# Transactions

A transaction is a behavioral sequence. Every clause produces a specific
`.fsm` state with deterministic timing.

It is useful to think of an ISF transaction as a hardware task: it consumes
cycles, can declare local ports as formal arguments, and activation sites can
pass actual signals through explicit bindings.

The hardware caveat is that the transaction is not a stack-allocated
software/SV-task call.

It lowers to static scheduled `.fsm` states, handoff signals, mux selections,
and generated top wiring.

Today the task-like port model is shipped for `(ports ...)` bindings on `do`,
`spawn`, and rule `trigger` activation sites.

Transaction port widths may be positive literals, actor-local scalar
parameter defaults, declared actor constants, or qualified imported package
scalar constants that resolve to positive integers. Generated child and
direct/non-generated transactions may also use same-transaction scalar
parameter defaults as port widths when they resolve to positive integers.
Omitted widths are one-bit.

Input bindings may pass scalar actor-side signals, numeric/exact-width
literals, or non-empty list expressions; output bindings still name scalar
writable actor-side targets.

Rule triggers bind transaction inputs only; output bindings require a caller
that waits for completion, such as `do` or the shipped spawn handoff path.

Spawned child transactions and generated blocking `do` activations support
per-instance parameter overrides through `(params ...)`.

Those parameter overrides are compile-time specialization of a static child
instance, not runtime payload actuals.

Parameterized rule triggers now use the same specialization model: they
elaborate generated child activation instances instead of writing mutable
parameter signals into a shared transaction body.

Direct `(on ...)` entry activation is explicitly not a parameter-override
site because it is the transaction's own guard, not a caller-owned generated
instance.

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

Generated child parameters consumed by default-resolved static timing lowering
have a stricter gate until full per-activation specialization exists.
Overrides that target repeat counts, wait counts, latency bounds, or
top-level await-local watchdog limits are accepted only when they resolve to
the same integer value as the child transaction parameter default; mismatches
fail closed before scheduled artifacts are emitted.

For rule triggers, a parameterized trigger also uses distinct generated
hardware. The generated instance name is
`{rule}_{transaction}_trigger_{ordinal}` so repeated lexical trigger sites do
not collide. The rule still emits the existing one-cycle trigger source and
payload source timing, then a generated trigger handoff DT drives the child
instance start and input handoff ports. Generated-child rule-trigger output
bindings copy the child output handoff into the scalar actor target under that
trigger instance's done-observer signal. Direct/local rule-trigger output
bindings remain rejected because a shared local target has no rule-specific
completion identity.

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
no per-call instance to specialize; the lowerer reports that direct
`(on ...)` activation is an entry guard, not a generated activation-site
parameter override. Transaction-local `params` on that transaction remain
definition defaults. If an author needs a statically specialized child
instance, use a generated activation form (`spawn`, parameterized blocking
`do`, or parameterized rule `trigger`) and pass runtime data through ports or
bindings.

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
  (<= (apb_transfer_wd 65534))    ;; watchdog: load max-1
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
(await PREADY (watchdog WD_LIMIT))    ;; actor constant or actor parameter override
(await PREADY (watchdog TX_LIMIT))    ;; same-transaction parameter override
```

**Timing**: 1 to watchdog_limit cycles. Self-looping.

The actor-level `(watchdog N)` and await-local `(watchdog N)` limit may use a
positive decimal literal, a declared actor constant, or an actor-local scalar
parameter default that resolves to a positive integer. Await-local watchdogs
on top-level transaction awaits may also use same-transaction scalar parameter
defaults that resolve to positive integers. Actor-level constants and actor
parameters resolve in the parser-visible watchdog scalar and still appear in
`actor_constants[]` or `actor_params[]`; await-local constants, actor
parameters, and top-level transaction parameters resolve before watchdog
counter injection. Same-transaction watchdog parameters shadow actor-level
static names and remain local lowering inputs.
Generated child activation overrides for top-level await-local watchdog
transaction parameters must preserve the child default value; mismatches fail
closed until per-activation watchdog specialization is shipped. The
rejected shape is a parent that activates a child whose
`(params (WD_LIMIT N))` default feeds an `(await ack (watchdog WD_LIMIT))`
clause, when the activation site passes a different value:

```text
(transaction parent
  (on start)
  (spawn worker as w0
    (params
      (WD_LIMIT 2)))         ;; <-- override mismatches the default
  (complete done))
(transaction worker
  (params
    (WD_LIMIT 4))            ;; child default drives the watchdog init
  (await ack (watchdog WD_LIMIT))
  (complete done))
```

The validator emits
`Transaction 'parent': spawn instance 'w0' overrides watchdog-limit
parameter 'WD_LIMIT' on child 'worker'; activation-site parameter
override-specialized watchdog limits remain deferred`. The deferred
lane is per-activation watchdog specialization, which would
respecialize the child's watchdog counter per call site.

One transaction currently has one watchdog counter. If a transaction contains
multiple awaits with distinct effective watchdog limits, FSMGen fails closed
until per-await counter reset semantics are selected.

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
(wait shared.WAIT_TWO)
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
- `wait PACKAGE.CONSTANT`: resolve the qualified imported package scalar
  constant as a static non-negative count, preserving the authored qualified
  token in `transaction_waits[]`.
- `wait count_signal`: in shipped runtime contexts, bypass on a runtime zero
  count; otherwise snapshot `count_signal` on the predecessor edge and consume
  exactly that many active wait cycles with a generated counter. Consecutive
  top-level runtime waits are allowed; a zero bypass from one wait immediately
  evaluates the next wait's zero/positive split, and the final
  sampled-counter edge of an active wait does the same for the following wait.
  Runtime waits can also follow top-level `await`, `stage`, `repeat` exit
  checks, `await_all`, `await_any`, and bank `load`/`store` states, where the
  predecessor's own advance condition is combined with the runtime count split
  and bank states keep their guarded scalarized assignments.
- `wait (<op> ...)`: use the same runtime zero-bypass and predecessor-edge
  snapshot contract as scalar runtime waits when every referenced signal has
  known width and the expression-width helper derives a positive result width.
  Division and modulo count expressions reject numeric or exact-width literal
  zero, actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisors before scheduled `.fsm` emission;
  dynamic scalar divisors are accepted but are not proven nonzero yet.

Pending samples immediately before a positive static wait piggyback onto the
first wait state, using the same sample materialization rule as drive/await
piggybacking.

Pending samples immediately before `(wait 0)` are preserved and materialize
on the next state-producing clause.

Static waits do not introduce a hidden wait counter; the scheduled `.fsm`
review artifact shows the exact fixed state chain for positive waits.
Static count sources are non-negative integer literals, actor constants,
actor-local scalar parameter defaults, and qualified imported package scalar
constants. Package constants must be atomic scalar constants: unqualified
package constants, aggregate constants, package member/item paths, and package
constants inside wait-count expressions fail closed.

Top-level runtime waits preserve pending samples with path-specific
materialization: the positive path samples in the first active wait state,
then counts greater than one continue in a generated wait-loop state that
does not repeat the sample.

The zero path uses a sample-preserving clone of the following state-producing
clause so no hidden sample-only cycle is inserted and the original following
state does not sample again after a positive wait.

This top-level subset is limited to following states that can carry the
zero-count sample without changing timing, including completion states that
preserve the delayed completion pulse and return-to-idle transition plus
independent scalar `set`/`update` states that neither read nor overwrite a
pending sample alias plus independent shift, assemble, and extract states
plus independent bank loads and stores plus top-level ready/valid stages plus
top-level await-all/await-any sync states whose collected done ports are
independent of pending sample aliases plus top-level spawn states whose
generated start handoff is independent of pending sample aliases plus
top-level transaction phase pass-through states plus top-level
bounded-eventual contract arm states; other successor shapes fail closed
until their sample materialization is specified.

Consecutive top-level runtime waits carry pending samples across zero-count
wait links with generated downstream wait-entry clones for zero-then-positive
paths and final compatible target clones for all-zero paths.

Repeat, while, and until loop decision/check states can also carry pending
samples when their repeat-counter assignment and loop condition are
independent of the pending sample alias.

Runtime waits can also follow transaction bank `load` and `store` states. The
bank state keeps its guarded scalarized assignments, and its unconditional
advance edge splits into positive-count counter load and zero-count bypass
paths.

Runtime waits inside `when` bodies and `switch` branches now use the same
one-shot positive sample plus zero-count clone scheme for sample-compatible
successors, including completion, independent scalar setter, independent
shift, independent assemble, and independent extract successors, while
preserving false, other-case, and fallthrough exits. Independent bank-load
and bank-store successors are also sample-compatible. Setters, shifts,
assemble states, extract states, bank-load states, and bank-store states that
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
`exit_state`, `counter_signal`, and `counter_width`.

Only positive static waits and accepted runtime waits create report entries.

Static waits report the resolved integer in `cycles` and keep the authored
literal, actor constant name, actor parameter name, or qualified package
constant token in `count_source`;
runtime scalar and runtime expression waits report `cycles` as null and
expose the source/counter metadata instead.

Expression waits use `count_kind` `runtime_expression` and keep the
normalized expression in `count_source`.

Malformed waits such as `(wait)`, `(wait 1 2)`, `(wait -1)`, non-scalar or
non-integer actor parameter counts, non-scalar or cross-transaction
transaction parameter counts, unknown package constants, unqualified or
aggregate package constants, package
member/item paths, package constants inside wait-count expressions,
unknown-width dynamic counts, unknown-width or malformed expression counts,
and unsupported runtime contexts fail closed.
Generated child activation overrides for wait-count transaction parameters
must preserve the child default value; mismatches fail closed until
per-activation wait-state specialization is shipped. The rejected shape is
a parent transaction that activates a child whose `(params (DELAY N))`
default feeds a `(wait DELAY)` clause, when the activation site passes a
different value:

```text
(transaction parent
  (on start)
  (spawn worker as w0
    (params
      (DELAY 2)))            ;; <-- override mismatches the default
  (complete done))
(transaction worker
  (params
    (DELAY 4))               ;; child default
  (wait DELAY)
  (complete done))
```

The validator emits
`Transaction 'parent': spawn instance 'w0' overrides wait-count
parameter 'DELAY' on child 'worker'; activation-site parameter
override-specialized wait counts remain deferred`. Same-value
overrides (for example `(DELAY 4)`) keep working; the deferred lane is
per-activation wait-state specialization that would respecialize the
child's wait expansion per call site.

Inline dynamic waits are supported in `when` and `repeat` bodies, `switch`
branches, and `while`/`until` bodies for the no-pending-sample subset.

Pending samples are also supported for `when` bodies and `switch` branches
when the selected zero-count successor can carry samples without changing
timing, including completion, independent scalar setter, and independent
shift, assemble, extract, bank-load, and bank-store successors.

The same pending-sample rule is also supported in `repeat`, `while`, and
`until` bodies for sample-compatible body successors.

Consecutive top-level runtime waits also preserve pending samples through
zero-count links when the final target can carry the sample.

Top-level stage successors preserve the original ready/valid barrier in their
sample-preserving zero-count clone.

Top-level await-all/await-any sync successors preserve the collected
done-port synchronization behavior.

Top-level spawn successors preserve the generated child start handoff.

Top-level transaction phase successors preserve the original pass-through
transition and apply only to transaction `(phase ...)` marker states, not
actor-level phase metadata.

Top-level contract arm successors preserve the original one-cycle monitor arm
request.

Loop decision/check successors preserve the original repeat counter decrement
or while/until branch decision.

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
counter construction. `count` may be a non-negative literal,
same-transaction scalar parameter default, non-negative actor constant,
non-negative actor scalar parameter default, qualified package scalar
constant, or known-width runtime scalar. Positive same-transaction parameter
counts resolve to a counter width and load that resolved value in the
scheduled `.fsm`.
Static zero counts from literal zero, actor constants, actor scalar
parameters, same-transaction scalar parameters, or package scalar constants
lower as transparent no-op regions with no counter, repeat init/check state,
repeat-body state, or `transaction_loops[]` entry. Plain `(do child)` and
plain `(spawn child as inst)` clauses inside statically zero repeat bodies are
pruned with the skipped body: no local child handoff, generated child `.fsm`,
generated top, activation instance, or loop report entry is emitted. If the
target transaction is otherwise live or has an explicit actor-input entry
guard, that transaction remains available; only the zero-count activation is
removed. Syntactically valid parameterized, bound, or domain-annotated
static-zero child activations are pruned the same way after activation
subclause shape validation; their dead payloads are not validated against
child parameter, port, or domain declarations.
Generated child activation overrides for repeat-count transaction parameters
must preserve the child default value; mismatches fail closed until
per-activation repeat counter specialization is shipped. The rejected
shape is a parent that activates a child whose `(params (ITER N))`
default feeds a `(repeat ITER ...)` clause, when the activation site
passes a different value:

```text
(transaction parent
  (on start)
  (do worker
    (params
      (ITER 2)))             ;; <-- override mismatches the default
  (complete done))
(transaction worker
  (params
    (ITER 4))                ;; child default drives the loop count
  (repeat ITER
    (wait 1))
  (complete done))
```

The validator emits
`Transaction 'parent': do instance 'parent_worker_do_0' overrides
repeat-count parameter 'ITER' on child 'worker'; activation-site
parameter override-specialized repeat counts remain deferred`. The
deferred lane is per-activation repeat counter specialization, which
would respecialize the child's loop counter per call site.

**What happens**:
1. Init state: `(<= (cnt N))` — load counter via D-input
2. Body states execute each iteration
3. Check state: `(<- (cnt (- cnt 1)))` — decrement via Q-named
4. `(?cnt (=1 → loop) (=0 → exit))` — decision tree

For a known-width runtime scalar count, the init state also tests the runtime
source value. A nonzero value enters the body. A zero value bypasses the body
and repeat check and transitions directly to the state after the repeat
region.

**Implicit signals**:
| Signal | Width | Purpose |
|--------|-------|---------|
| `{tx}_cnt` | inferred | Repeat counter |

Repeat counter width is inferred from the count expression. Positive decimal
literal counts use the minimum width that can represent the loaded count.
Declared positive actor constants, actor-local scalar parameter defaults, and
qualified imported package scalar constants use the resolved integer value as
width evidence while preserving the authored count token in the scheduled
`.fsm` load. Static zero counts from literal zero, actor constants, actor
scalar parameters, same-transaction scalar parameters, or package scalar
constants lower as transparent no-op regions with no repeat counter or loop
report entry when the body contains no activation or contains only child
activation sites whose valid subclauses can be pruned with the skipped body.
Named dynamic counts use
their known interface or sample-derived width and bypass the body when the
runtime value is zero.
Unknown names, unqualified package constants, aggregate package constants,
package member/item paths, non-scalar actor parameters, non-scalar
transaction parameters, cross-transaction parameters, malformed scalar
tokens, package constants inside repeat-count expressions, expression-valued
counts, and malformed static-zero child activation subclause syntax fail
closed before scheduled `.fsm` emission.
Repeats nested in switch branches declare the same transaction counter,
widened to the largest branch requirement.

The shipped repeat-body clause surface is named drive calls, `await`,
`sample`, `update`, `set`, `shift_left`, `shift_right`, `assemble`,
`extract`, actor-owned bank `store` and `load`, shipped `wait` clauses, and
the top-level local blocking `(do child)` subset.

Repeat-body local `do` asserts the local child `start`, waits for the child's
fresh `done` pulse, and only then reaches the repeat check back-edge.

Repeats directly inside a top-level `when` body accept local `(do child)`
under that same parent-module contract, plain generated-child `(do child)`
when the target child is already emitted as a generated child by another
activation site, and generated blocking `(do child (params ...))` with static
parameter overrides.

The generated when-contained forms emit one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance for the lexical nested do
site and apply parameter overrides once when present.

All shipped when-contained forms keep samples around the nested do in source
order and reach the branch-owned repeat check only after a fresh local or
generated child done handoff.

Repeats directly inside a top-level `switch` branch accept the same local,
plain generated-child `(do child)`, and static-parameter generated `(do child
(params ...))` forms with the same deterministic generated-instance naming,
static parameter application once when present, source-order sample timing,
and done-gated repeat check.

The when-contained and switch-contained generated nested `do` subsets also
accept `(bind ...)` when static `(params ...)` overrides are present, wiring
the input/output binding handoffs once in the generated top for that lexical
nested do site.

The when-contained and switch-contained generated nested `do` subsets also
accept declared same-domain `(domain NAME)` metadata when static `(params
...)` overrides are present.

A plain local `(do child)` and a same-domain generated `(do child (params ...))`
(with `(bind ...)`/`(domain NAME)` when static params are present) inside a
`(repeat ...)` that sits directly in a single `(while ...)` or `(until ...)`
body now lower, reusing the proven repeat schedule inside the loop body (see the
control-flow chapter); a generated `do` instantiates its child in the `_top`
composition. Inside a loop-contained repeat, `spawn` and a cross-domain
generated `do` still fail closed: the spawn form emits the targeted
`loop-contained repeat-body spawn remains deferred` diagnostic, and a
cross-domain generated `do` emits `cross-domain repeat-body do remains
deferred`. A repeat reached through an extra loop ancestor (for
example `(while c1 (when c2 (repeat ...)))`) still emits `loop-contained
repeat-body do remains deferred`. A plain local `(do child)` and a same-domain
generated `(do child (params ...))` at deeper branch nesting (`when⁺ → repeat`,
`switch → when⁺ → repeat`) also lower (a generated `do` instantiates its child
in the `_top`); a deeper-nested cross-domain generated `do` fails closed with
`cross-domain repeat-body do remains deferred` and a deeper-nested `spawn` with
`deeper-nested repeat-body spawn remains deferred`. The original generic "supported only for
top-level..." message remains as a safety-net fallback for shapes not
yet classified.

The shipped repeat-body clause surface also includes generated blocking `(do
child)` when the target child is already emitted as a generated child by
another activation site, and `(do child (params ...) [(bind ...)] [(domain
NAME)])` with static parameter overrides, optional input/output port
bindings, and optional declared same-domain ownership metadata: it emits one
generated do instance for the lexical repeat-body do site, applies the
parameter override once when present, wires binding handoff ports once when
present, records same-domain ownership for generated-composition and
clock-domain report summaries when `(domain NAME)` is present, and waits for
that instance's done handoff before the repeat check.

Samples may appear before or after repeat-body `do`; pending samples before
`do` materialize before the do state, while pending samples after `do`
materialize after the do state's fresh done guard and before the repeat
check.

The shipped repeat-body clause surface also includes the top-level spawn plus
same-body `await_all` subset with optional static `(params ...)` overrides,
optional `(bind ...)` port handoffs, and optional declared same-domain
`(domain NAME)` ownership metadata.

Single-pending repeat-body `await_any` is also shipped when exactly one
repeat-body spawn is pending.

Multi-pending repeat-body `await_any` is shipped only as an observation point
when a later same-body `await_all` drains the same outstanding spawned
children before the repeat check; new repeat-body `spawn` or `do` clauses
before that drain remain rejected.

A repeat directly inside a top-level `when` body may also contain one or more
generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
sites, provided the same nested repeat body reaches `(await_all done)` before
the nested repeat check can loop.

A repeat directly inside a top-level `switch` branch may contain the same
multiple generated-spawn plus same-body `await_all` subset.

Both branch-contained paths may use single-pending `(await_any done)`
directly when exactly one generated child is pending.

Both branch-contained paths may also use multi-pending `(await_any done)` as
an observation point when a later same-body `(await_all done)` drains the
same outstanding generated children before the nested repeat check can loop.

Those branch-contained nested spawns reuse the static generated-child handoff
model, preserve source-order samples before the spawn or sync state, and keep
the nested repeat check gated by the spawned child done handoffs.

In the top-level `when` body and top-level `switch` branch forms, the same
nested repeat body may also run a local plain `(do child)` while generated
nested spawns are pending either before or after a prior multi-pending
`(await_any done)` observation, provided a later same-body `(await_all done)`
drains every outstanding generated spawn before the nested repeat check can
loop.

That local do target remains in the parent scheduled module, waits for its
own fresh local done pulse, and does not clear the generated-spawn done set.
The same branch-contained local-do path may then start one or more additional
generated nested spawns before the mandatory same-body `(await_all done)`
drain, either with no active multi-pending `(await_any done)` before the
later spawn or after the local `do` follows a prior multi-pending observation.
The later spawn joins the outstanding generated child set, and the
`await_all` drain observes both the pre-do and post-do generated spawns before
the nested repeat check can loop. In the prior-observation form, that
local-do do-then-spawn path may also run a second post-spawn multi-pending
`(await_any done)` observation before the mandatory same-body
`(await_all done)` drain. Both observations leave the outstanding generated-
spawn done set live, and the final drain observes both pre-do and post-do
generated spawns before the nested repeat check can loop. That same local-do
do-then-spawn path may also run a post-spawn multi-pending `(await_any done)`
observation before the final same-body `(await_all done)` drain when no prior
multi-pending observation is active before the later spawn. The post-spawn
observation leaves both pre-do and post-do generated-spawn done handoffs live
for that final drain.

The top-level `when` body and top-level `switch` branch forms also support
plain generated-child `(do child)` in that pending-spawn interval when the
target child is already emitted as a generated child by another activation
site. That generated do site owns one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance, waits for that instance's
fresh done handoff, and does not clear the pending generated-spawn done set.
That same plain generated-child do may then start one or more additional
generated nested spawns before the mandatory same-body `(await_all done)`
drain, either with no active multi-pending `(await_any done)` before the later
spawn or after the generated-child `do` follows a prior multi-pending
observation. The generated do instance must complete before the later spawn
starts, and the `await_all` drain observes both pre-do and post-do generated
spawns before the nested repeat check can loop. In the prior-observation
form, a second multi-pending `(await_any done)` after the later spawn remains
fail-closed. The same
plain generated-child do-then-spawn shape may also run a post-spawn
multi-pending `(await_any done)` observation before that final drain when no
prior multi-pending observation is active before the later spawn; the
observation leaves both pre-do and post-do generated-spawn done handoffs live
for the later same-body `await_all`.

The same branch-contained forms support static-parameter generated `(do child
(params ...))` in that pending-spawn interval; the generated do site keeps
its authored static parameter binding and still leaves the pending
generated-spawn done set live for the later drain.

That same static-parameter generated do may then start one or more additional
generated nested spawns before the mandatory same-body `(await_all done)`
drain, either with no active multi-pending `(await_any done)` observation
before the later spawn or after the generated do follows a prior multi-
pending observation. The generated do instance's fresh done handoff gates the
later spawn state, and the `await_all` drain observes both pre-do and post-do
generated spawns before the nested repeat check can loop. That same
static-parameter generated-do do-then-spawn shape may also run a post-spawn
multi-pending `(await_any done)` observation before the final same-body
`(await_all done)` drain in either branch: when no prior multi-pending
`(await_any done)` observation is active before the later spawn, or after the
generated do follows a prior multi-pending observation. Both `await_any`
observations leave the outstanding generated-spawn done set live for the
final drain.

The top-level `when` body and top-level `switch` branch forms also support
static-parameter generated `(do child (params ...)

(bind ...))` after a prior multi-pending `(await_any done)` observation in
that interval; the generated do site wires generated-top input/output binding
handoffs once and still leaves the pending generated-spawn done set live for
the later drain.

That same bound generated do may then start one or more additional generated
nested spawns before the mandatory same-body `(await_all done)` drain, either
when no multi-pending `(await_any done)` observation is active before the
later spawn or after the generated do follows a prior multi-pending
observation. The generated do instance's fresh done handoff gates the later
spawn state, generated-top binding handoffs stay scoped to the do instance,
and the `await_all` drain observes both pre-do and post-do generated spawns
before the nested repeat check can loop. That same bound generated-do
do-then-spawn shape may also run a post-spawn multi-pending `(await_any done)`
observation before the final same-body `(await_all done)` drain in either
branch: when no prior multi-pending `(await_any done)` observation is active
before the later spawn, or after the generated do follows a prior
multi-pending observation. Both `await_any` observations leave the
outstanding generated-spawn done set live for the final drain, and
generated-top binding handoffs remain scoped to the do instance across the
post-spawn observation.

The same branch-contained forms also support static-parameter same-domain
generated `(do child (params ...) [(bind ...)] (domain NAME))` after a prior
multi-pending `(await_any done)` observation, preserving declared ownership
metadata without implying CDC.

The top-level `when` body nested repeat local `(do child)` subset may also
place `(await_any done)` after the local do as a post-do multi-pending
observation while generated nested spawns remain pending before the mandatory
later same-body `(await_all done)` drain.

The top-level `switch` branch nested repeat local `(do child)` subset
supports the same post-do multi-pending observation and later-drain contract
while generated nested spawns remain pending before the same-body `await_all`
drain.

The top-level `when` body nested repeat plain generated-child `(do child)`
subset supports the same post-do multi-pending observation and later-drain
contract while generated nested spawns remain pending before the same-body
`await_all` drain; it waits for the deterministic generated do instance's
fresh done handoff before the observation.

The top-level `when` body and top-level `switch` branch nested repeat
static-parameter generated `(do child (params ...))` subsets support the same
post-do multi-pending observation and later-drain contract while generated
nested spawns remain pending before the same-body `await_all` drain; the
generated do waits for the deterministic generated do instance's fresh done
handoff before the observation and preserves the static generated-top
parameter override.

The top-level `when` body and top-level `switch` branch nested repeat
static-parameter bound generated `(do child (params ...) (bind ...))` subsets
support the same post-do observation and later-drain contract while also
wiring generated-top input/output binding handoffs for the generated do
instance.

The top-level `when` body and top-level `switch` branch nested repeat
same-domain generated `(do child (params ...) [(bind ...)] (domain NAME))`
subsets support the same post-do observation and later-drain contract while
retaining declared ownership metadata in generated-composition,
domain-partition, and schedule-report clock-domain summaries. Those
same-domain generated-do subsets may also start one or more later generated
nested spawns before the mandatory same-body `(await_all done)` drain, either
when no multi-pending `(await_any done)` observation is active before the
later spawn or after the generated do follows a prior multi-pending
observation; the generated do instance's fresh done handoff gates the later
spawn state and declared ownership metadata remains scoped to the generated
do instance. That same same-domain generated-do do-then-spawn shape may also
run a post-spawn multi-pending `(await_any done)` observation before the
final same-body `(await_all done)` drain in either branch: when no prior
multi-pending `(await_any done)` observation is active before the later
spawn, or after the generated do follows a prior multi-pending observation.
Both `await_any` observations leave the pre-do and post-do generated-spawn
done set live for the final drain while retaining declared ownership metadata
for the generated do instance.

The top-level `switch` branch nested repeat plain generated-child `(do
child)` subset supports the same post-do multi-pending observation and
later-drain contract while generated nested spawns remain pending before the
same-body `await_all` drain; it waits for the deterministic generated do
instance's fresh done handoff before the observation.

Cross-domain repeat-body `do`, generated or spawned nested activation beyond
the documented top-level branch-contained generated `do` cases and these
branch-contained spawned cases, broader outstanding-child semantics, `stage`,
`contract`, deeper branch nesting, nested `while`, and nested `until` remain
outside the shipped repeat-body subset.

Samples may appear before or after repeat-body spawn as long as the same
repeat body reaches same-body `await_all`, single-pending `await_any`, or
multi-pending `await_any` followed by same-body `await_all` before the repeat
check can loop.

Pending samples materialize in an explicit sample state at their source-order
timing point: before a later spawn state for sample-before-spawn ordering, or
before the sync state for sample-after-spawn ordering.

The same sample timing applies to the documented branch-contained nested
spawn subsets before their same-body sync.

The shipped repeat-body child-activation subset is `(do child)` for local
child transactions, generated-child `(do child)` when the target is already
generated by another activation site, generated `(do child (params ...)
[(bind ...)] [(domain NAME)])` for static parameter overrides, optional
input/output binding handoffs, and optional same-domain ownership metadata,
plus `(spawn child as instance [(params ...)] [(bind ...)] [(domain NAME)])`
followed by a same-body `(await_all done)` before the repeat check can loop,
including the documented top-level when-body generated-spawn and
switch-branch nested generated-spawn subsets,

and the documented top-level when-body nested local or plain generated-child
`do` while generated nested spawns are pending before a same-body `await_all`
drain, plus the documented top-level switch-branch nested local `do` while
generated nested spawns are pending before a same-body `await_all` drain.

The lexical spawn name denotes one static generated child instance reused
across repeat iterations, optional parameter overrides specialize that
instance once in the generated top, optional input/output bindings create
generated handoff ports once for that instance, and optional domain
annotations group the static child with a declared same-domain activation
owner without implying CDC behavior.

`(await_any done)` may replace `await_all` directly when that repeat body has
exactly one pending spawn.

With multiple pending spawns, `await_any` may appear only before a later
same-body `await_all` drain that keeps the repeat check unreachable until
every outstanding child has finished.

Samples around repeat-body spawn and do lower into explicit source-order
sample states, so the scheduled `.fsm` shows capture timing before spawn/do,
before spawn sync, between multi-pending `await_any` and its drain, or after
do completion before the repeat check.

The local `(do child)` form is also shipped inside a repeat that is directly
inside a top-level `when` body or directly inside a top-level `switch` branch.

Those nested repeat forms also accept a plain generated-child `(do child)`
target that is already generated elsewhere. The top-level `when` nested
repeat form also accepts static `(params ...)` on generated blocking `do`.

That nested generated do site owns one
`{parent}_{child}_repeat_do_{ordinal}` instance, applies parameter overrides
once when present, uses no port binding or domain annotation, and waits for
the generated instance's fresh done handoff before the nested repeat check.

Deeper branch/loop placement remains backlog.

Example: a parent can spawn `worker` once, then call the already generated
`worker` from a repeat nested inside a top-level `when` without reintroducing
a local child body:

```lisp
(transaction parent
  (on start)
  (spawn worker as w0)
  (await_all done)
  (when cond
    (repeat loops
      (sample status as before)
      (do worker)
      (sample status as after)))
  (complete done))
```

That nested `(do worker)` emits a generated do instance such as
`parent_worker_repeat_do_0` alongside the lexical spawn instance `w0`. The
parent scheduled `.fsm` starts `parent_worker_repeat_do_0_start>`, waits for
`parent_worker_repeat_do_0_done`, then runs the `after` sample before the
nested repeat check.

The top-level `when` nested repeat also supports static parameter overrides on
that generated do site:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (sample status as before)
      (do worker
        (params
          (WIDTH 16)))
      (sample status as after)))
  (complete done))
```

The generated top instantiates `parent_worker_repeat_do_0` once with
`WIDTH 16`; each repeat iteration starts that same generated instance and
waits for its fresh done handoff before the `after` sample and repeat check.

The top-level `when` nested repeat also supports generated spawn sites when
the same nested repeat body drains them through `await_all`; the
single-pending `await_any` form remains limited to exactly one pending
generated child:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (sample status as before)
      (spawn worker as w0
        (params
          (WIDTH 16))
        (bind
          (input data payload)
          (output resp result))
        (domain core))
      (sample status as after)
      (await_all done)))
  (complete done))
```

The lexical instance name `w0` denotes one static generated child instance in
the generated top. `WIDTH 16`, the input/output binding handoffs, and declared
same-domain ownership metadata are applied once for that instance. The nested
repeat can loop only after the sync state observes `w0_done`; the `before`
sample appears before the spawn state and the `after` sample appears before
the sync state.

With two or more generated spawns, the same-body sync must be `await_all` so
all generated child done handoffs are observed before the nested repeat can
re-enter:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (params (WIDTH 16))
        (bind
          (input data payload0)
          (output resp result0))
        (domain core))
      (sample status as between)
      (spawn worker as w1
        (params (WIDTH 32))
        (bind
          (input data payload1)
          (output resp result1))
        (domain core))
      (await_all done)))
  (complete done))
```

This emits one generated child instance per lexical spawn name, keeps the
`between` sample before the second spawn, and gates the nested repeat check on
both `w0_done` and `w1_done`.

For the exactly-one-pending nested spawn case, the same `when` body may use
`await_any` directly because it observes the same single child done handoff:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (params (WIDTH 16))
        (bind
          (input data payload)
          (output resp result))
        (domain core))
      (await_any done)))
  (complete done))
```

With multiple pending nested spawns in a top-level `when` body, `await_any`
may be used as an observation point only when a later same-body `await_all`
drains the same outstanding children:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (params (WIDTH 16)))
      (spawn worker as w1
        (params (WIDTH 32)))
      (await_any done)
      (sample status as after_any)
      (await_all done)))
  (complete done))
```

The `await_any` state advances after either `w0_done` or `w1_done`, but the
outstanding done set remains live until the mandatory `await_all` drain. The
nested repeat check remains unreachable until both done handoffs have been
observed. After a multi-pending `await_any` observation, a new nested `spawn`
or any generated `do` before that drain remains fail-closed. A local
`(do child)` is shipped only for the top-level `when` body nested-repeat path
when the later same-body `await_all` drain is still present.

A repeat directly inside a top-level `when` body may run a local child while
generated nested spawns remain pending, then drain those generated spawns
through same-body `await_all`. The local do may appear either before any
multi-pending `await_any` observation or after that observation:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (params (WIDTH 16))
        (bind
          (input data payload)
          (output resp result))
        (domain core))
      (do local_worker)
      (sample status as after_do)
      (await_all done)))
  (complete done))
```

Here `local_worker` remains a local child transaction in the parent scheduled
module. The nested do state starts `local_worker`, waits for its fresh local
done pulse, and then the `after_do` sample runs before the `await_all` state.

The generated-spawn done set remains live across the local do, so the nested
repeat check is still gated by `w0_done` at the same-body `await_all` drain.

The same top-level `when` path may observe any one of multiple generated
children first and still run a local child before the mandatory drain:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (params (WIDTH 16)))
      (spawn worker as w1
        (params (WIDTH 32)))
      (await_any done)
      (do local_worker)
      (await_all done)))
  (complete done))
```

In this form `await_any` only observes `w0_done` or `w1_done`; it does not
remove either generated child from the outstanding set. The local do waits for
`local_worker_done`, then `await_all` still waits for both generated done
handoffs before the nested repeat check can re-enter.

The top-level `switch` branch nested-repeat subset accepts the same
local-do-after-`await_any` shape when the later same-body `await_all` drain
still gates re-entry:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)
        (do local_worker)
        (await_all done))))
  (complete done))
```

Generated `do` forms with static parameters, optional binding handoffs, and
same-domain metadata are documented below as separate shipped subsets.

Static-parameter generated `do` after prior multi-pending `await_any` is
shipped only for the top-level `when` body and top-level `switch` branch
nested subsets documented below. Static-parameter generated `do` with bind
handoffs after prior multi-pending `await_any` is shipped only for the top-
level `when` body and top-level `switch` branch nested subsets documented
below. Same-domain generated `do` after prior multi-pending `await_any` is
shipped only for the top-level `when` body and top-level `switch` branch
nested subsets documented below; `await_any` after the do and new nested
`spawn` after the do before the drain remain outside this local do subset.

The same top-level `when` body pending-spawn interval may run a plain
generated-child `(do child)` when that child already has a generated instance
elsewhere, for example from another lexical spawn. The generated do instance
is separate from the pending spawn instance, and the later `await_all` still
drains the spawned child:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (sample status as before)
      (spawn worker as w0)
      (do worker)
      (sample status as after_do)
      (await_all done)))
  (complete done))
```

Lowering emits `w0` for the pending spawn and
`parent_worker_repeat_do_0` for the blocking generated-child do site. The do
state starts `parent_worker_repeat_do_0_start>`, waits for
`parent_worker_repeat_do_0_done`, then runs `after_do` before the `await_all`
state. The nested repeat check is still gated on `w0_done`, so the spawned
child cannot be restarted by the loop until the same-body drain observes its
fresh done handoff. Static `(params ...)` overrides on that pending generated
do are shipped for both top-level `when` and top-level `switch` branch nested
repeats. Both top-level branch-contained subsets may also place that static-
parameter generated do after a prior multi-pending `await_any` observation
while a later same-body `await_all` still drains every pending generated spawn.

Static
`(params ...)` plus `(bind ...)` handoffs on the pending generated do are
shipped for both top-level branch-contained subsets, and
same-domain `(domain NAME)` metadata on those static generated do sites is
also shipped. The top-level `when` body and top-level `switch` branch forms
may place the plain generated-child `(do child)` after a prior multi-pending
`await_any` observation while generated nested spawns remain pending; the
generated do still waits only for `parent_worker_repeat_do_0_done`, and the
later same-body `await_all` still drains every pending generated spawn before
nested repeat re-entry.

The bound when-contained form keeps the pending generated spawn and the
blocking generated `do` as separate generated instances:

```lisp
(transaction parent
  (on start)
  (when cond
    (repeat loops
      (sample status as before)
      (spawn worker as w0
        (params
          (WIDTH 16))
        (bind
          (input addr payload)
          (output data spawn_resp)))
      (do worker
        (params
          (WIDTH 32))
        (bind
          (input addr req_addr)
          (output data resp)))
      (sample status as after_do)
      (await_all done)))
  (complete done))
```

Lowering emits `w0` for the spawn and `parent_worker_repeat_do_0` for the
blocking `do`. The generated top applies `(WIDTH 32)` and the `addr`/`data`
binding handoffs to `parent_worker_repeat_do_0` only; `w0_done` remains live
until the later same-body `await_all` drain.

The direct switch-branch analogue is also shipped. A selected branch may run a
local plain `(do child)` while one or more generated nested spawns remain
pending, and the same branch-contained nested body must drain those generated
spawns through same-body `await_all`:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (sample status as before)
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input data payload)
            (output resp result))
          (domain core))
        (do local_worker)
        (sample status as after_do)
        (await_all done)))
    (1
      (sample status as other)))
  (complete done))
```

Only the selected branch enters the nested repeat region. The generated top
still owns one static `w0` instance, applies the optional parameter/binding
and same-domain metadata once. The local `do` starts `local_worker`, waits for
the local child's fresh done pulse, and leaves `w0_done` pending for the later
`await_all` drain. The switch-branch repeat check remains unreachable until
that same-body `await_all` observes every outstanding generated child done
handoff.

The switch-branch generated-bound form uses the same two-instance proof as the
when form:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (spawn worker as w0
          (params
            (WIDTH 16))
          (bind
            (input addr payload)
            (output data spawn_resp)))
        (do worker
          (params
            (WIDTH 32))
          (bind
            (input addr req_addr)
            (output data resp)))
        (await_all done)))))
  (complete done))
```

Lowering emits `w0` for the switch-branch spawn and
`parent_worker_repeat_do_0` for the blocking `do`. The generated top applies
the do's `(WIDTH 32)` override and `addr`/`data` binding handoffs to the do
instance only; `w0_done` stays pending until the later same-body `await_all`.

The selected branch may also run a plain generated-child `(do child)` while
the generated spawn remains pending:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (sample status as before)
        (spawn worker as w0)
        (do worker)
        (sample status as after_do)
        (await_all done)))
    (1
      (sample status as other)))
  (complete done))
```

Lowering emits `w0` for the pending spawn and
`parent_worker_repeat_do_0` for the blocking generated-child do site. The do
state waits for `parent_worker_repeat_do_0_done` only; `w0_done` remains
pending until the later `await_all` drain gates the switch-branch nested
repeat check.

The same selected branch may use static parameter overrides on that generated
`do` while the earlier generated spawn remains pending:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (sample status as before)
        (spawn worker as w0)
        (do worker
          (params
            (WIDTH 16)))
        (sample status as after_do)
        (await_all done)))
    (1
      (sample status as other)))
  (complete done))
```

The generated top instantiates `w0` for the spawn and
`parent_worker_repeat_do_0` for the blocking `do`, applying `(WIDTH 16)` only
to the generated `do` instance. The `do` consumes only
`parent_worker_repeat_do_0_done`; `w0_done` remains live until the later
same-body `await_all` drain. Binding or domain subclauses on that pending
generated `do`, `await_any` before or after it, and a new nested `spawn` after
it before the drain remain fail-closed.

When a switch branch contains two generated spawns, `await_all` is the shipped
drain. The same mandatory-drain rule also allows multi-pending `await_any`
before a later `await_all`:

```lisp
(transaction parent
  (on start)
  (switch mode
    (0
      (repeat loops
        (spawn worker as w0
          (params (WIDTH 16))
          (bind
            (input data payload0)
            (output resp result0))
          (domain core))
        (sample status as between)
        (spawn worker as w1
          (params (WIDTH 32))
          (bind
            (input data payload1)
            (output resp result1))
          (domain core))
        (await_any done)
        (sample status as after_any)
        (await_all done)))))
  (complete done))
```

The generated top owns `w0` and `w1` as separate static child instances, and
the nested repeat check is guarded by both done handoffs. `await_any` observes
either done handoff first; it does not clear the outstanding set.

The same generated-child shape is supported for a repeat directly inside a
top-level `switch` branch:

```lisp
(transaction parent
  (on start)
  (spawn worker as w0)
  (await_all done)
  (switch mode
    (0
      (repeat loops
        (sample status as before)
        (do worker)
        (sample status as after)))
    (1
      (sample status as other)))
  (complete done))
```

Only the selected branch enters the generated-child nested repeat region. The
generated do instance still has deterministic
`{parent}_{child}_repeat_do_{ordinal}` naming and the branch-owned repeat
check is reached only after that instance reports fresh done.

The repeat count is not an elaboration count. It is loaded into a runtime
counter. A declared positive actor constant or actor-local scalar parameter
default gives static counter-width evidence, but FSMGen still emits the
authored count token as the load value. Static zero counts from literal zero,
actor constants, actor scalar parameters, same-transaction scalar parameters,
or package scalar constants lower as transparent no-op regions with no
counter, repeat init/check state, repeat-body state, or `transaction_loops[]`
entry. Plain static-zero repeat-body `do` and `spawn` child activations are
pruned with no generated child/top or local handoff artifact when their
targets are not otherwise live; syntactically valid specialized child
activations are pruned the same way after activation subclause shape
validation. A named count may
be a dynamic scalar signal when its
width is known. Dynamic counts make latency data-dependent rather than
statically fixed; verification and reports need either a known width-derived
bound or an explicit future bound if tighter proof is required. Known-width
runtime scalar counts skip the body when the runtime value is zero. Unknown
names, non-scalar actor parameters, non-scalar transaction parameters,
cross-transaction parameters, expression-valued counts, and generated-top
repeat-count specialization remain deferred and fail closed rather than
falling back to an implicit counter.

For the shipped repeat-body spawn subset, `(spawn child as name)` may add
optional `(params ...)`, `(bind ...)`, and `(domain NAME)` subclauses while
still reusing one static child instance named `name`.

It does not elaborate one child per iteration.

The same repeat body must reach `(await_all done)` or a single-pending
`(await_any done)` before the repeat check can loop, so a later iteration
cannot start the static instance again until its fresh completion has been
observed.

Multi-pending `(await_any done)` is accepted only as an observation point
before a later same-body `(await_all done)` drains the same outstanding spawn
set.

Binding handoff ports are generated once for the lexical instance and wired
in the generated top just like top-level spawn bindings.

Domain annotations are accepted only as declared same-domain ownership
metadata; cross-domain activation remains a CDC/backlog item. The
rejected shape is a repeat-body generated `(do TARGET (domain X))`
where `X` names a domain different from the calling transaction's
domain:

```text
(clock-domains
  (domain core (clock clk) (reset rst_n) :default)
  (domain aux (clock aux_clk) (reset aux_rst_n)))
(transaction parent
  (domain core)              ;; calling transaction is in core
  (on start)
  (repeat loops
    (do worker
      (params (ITER 4))
      (domain aux)))         ;; <-- target is in aux, not core
  (complete done))
(transaction worker
  (domain aux)               ;; target lives in aux
  (params (ITER 4))
  (repeat ITER
    (wait 1))
  (complete done))
```

The validator emits
`Transaction 'parent': repeat-body generated do target 'worker' is
in a different clock domain than the calling transaction;
cross-domain repeat-body do remains deferred`. The same diagnostic
fires with `when-body nested repeat` or `switch-branch nested repeat`
prefixes when the cross-domain `do` is nested inside a top-level
`when` body or `switch` branch. The deferred lane is cross-domain
repeat-body `do` lowering, which would require CDC sync wrappers,
generated-top CDC instantiation, and schedule-report extensions.
A `(do TARGET (domain X))` clause without a cross-domain mismatch
(target in the same domain as the calling transaction) keeps working
as same-domain ownership metadata.

Samples around repeat-body spawn are accepted only when the same-body sync
that consumes the spawned done ports still appears before the repeat check.

Sample-before-spawn materializes before the spawn state; sample-after-spawn
materializes before the sync state. The branch-contained nested subsets can
have multiple generated spawns on the same-body `await_all` path, and may
observe multi-pending same-body `await_any` only when a later same-body
`await_all` drains those same outstanding generated children. The direct
single-pending same-body `await_any` path is still exactly one generated
spawn. In the top-level `when` body and top-level `switch` branch
nested-repeat subsets, local plain `(do child)` may appear while generated
nested spawns are pending before or after a prior multi-pending `await_any`
observation, as long as a later same-body `await_all` drain still follows.

The local do waits on the local child's fresh done pulse and leaves
generated-spawn done handoffs pending for the later drain. Those same
branch-contained subsets may also run plain generated-child `(do child)` in
that interval when the target is already generated elsewhere; that generated
do waits on its generated do instance's fresh done handoff and still leaves
spawned done handoffs pending for the later drain.

The top-level `when` body and top-level `switch` branch nested subsets may
additionally run static-parameter generated `(do child (params ...))` in that
interval; that generated do preserves static generated-top parameter binding,
waits on its generated do instance's fresh done handoff, and still leaves
spawned done handoffs pending for the later drain.

The top-level `when` body and top-level `switch` branch nested subsets may
additionally run static-parameter generated
`(do child (params ...) (bind ...))` in that interval; that generated do wires
generated-top input/output binding handoffs once and still leaves spawned done
handoffs pending for the later drain. The top-level `when` body and top-level
`switch` branch nested subsets may additionally carry declared same-domain
metadata on that generated do:
`(do child (params ...) [(bind ...)] (domain NAME))`. The domain annotation is
metadata for the deterministic generated do instance; it does not imply CDC,
does not clear pending generated-spawn done handoffs, and still requires the
later same-body `await_all` drain. New spawn after that generated do before
the drain and generated-do await-any-after-do forms remain rejected.

Example:

```lisp
(transaction parent
  (domain core)
  (on start)
  (when cond
    (repeat loops
      (spawn worker as w0
        (domain core))
      (do worker
        (params
          (WIDTH 32))
        (bind
          (input addr req_addr)
          (output data resp))
        (domain core))
      (await_all done)))
  (complete done))
```

The generated do instance is `parent_worker_repeat_do_0`. It keeps its own
`start`/`done` handoff and binding handoff ports, is grouped with `core` in
clock-domain child-instance metadata, and the later `await_all` still waits on
the pending spawned `w0_done` before the nested repeat can loop.

The switch-branch form uses the same generated instance and drain rule inside
the selected branch:

```lisp
(switch mode
  (0
    (repeat loops
      (spawn worker as w0
        (domain core))
      (do worker
        (params
          (WIDTH 32))
        (bind
          (input addr req_addr)
          (output data resp))
        (domain core))
      (await_all done))))
```

For the shipped repeat-body local `do` subset, `(do child)` remains a local
child activation when the target child remains in the parent scheduled module.

If the same target child is already emitted as a generated child by another
activation site, the plain repeat-body `(do child)` uses a generated do
instance for that lexical repeat-body site instead of trying to call a local
child body that is no longer present in the parent module.

For the shipped repeat-body generated `do` subset,
`(do child)` may be selected by an already generated child target, while
`(do child (params ...) [(bind ...)] [(domain NAME)])` is selected by static
parameter overrides and may also carry input/output port bindings plus
same-domain ownership metadata. Binding handoff ports and domain metadata are
generated once for the deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance. Repeat-body generated `do`
still rejects cross-domain activation.

Samples around repeat-body `do` are explicit timing states. A sample before
`do` appears before the child start state; a sample after `do` appears only
after the do state observes the child's fresh done handoff and before the
repeat counter check.

Example:

```lisp
(transaction parent
  (on start)
  (repeat loops
    (do worker
      (params
        (WIDTH 16))
      (bind
        (input addr req_addr)
        (output data resp))))
  (complete done))
```

This emits one generated child instance named
`parent_worker_repeat_do_0`. The generated top applies `WIDTH=16` once and
wires the input handoff `parent_worker_repeat_do_0_addr` from `req_addr` and
the output handoff `parent_worker_repeat_do_0_data` back to `resp`. The parent
`.fsm` records those handoffs under `-parent_worker_repeat_do_0_port_bindings`,
and schedule JSON exposes `transaction_port_bindings[]` entries with
`site_kind: "do"`, `actor_endpoint_kind: "signal"`, and
`binding_timing: "generated_live_handoff"` for the input handoff,
`binding_timing: "done_guarded"` for the output copy, and
`instance: "parent_worker_repeat_do_0"`. If the actor declares clock domains,
the same source may add `(domain core)` beside the `params`/`bind` clauses;
schedule JSON then groups
`parent_worker_repeat_do_0` under the `core` `clock_domains[].child_instances`
summary. The repeat loop still waits for `parent_worker_repeat_do_0_done`
before decrementing/checking the repeat counter.

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

The shipped `while`/`until` body surface is the same inline transaction subset
used by `when`/`switch`: named drives, `await`, `sample`, `complete`, `repeat`,
`update`, `set`, shift/assemble/extract data operations, actor-owned bank
`store`/`load`, nested `when`, and waits. `while`/`until` bodies continue to
reject `do`, `spawn`, `await_all`, `await_any`, `stage`, `contract`, and nested
loops until their re-entry, child-lifetime, and report semantics are specified.

The shipped repeat-body spawn plus same-body `await_all` or single-pending
same-body `await_any` subset applies to top-level `repeat` bodies and, in the
narrower branch-contained forms documented above, to repeats directly inside
a top-level `when` body or top-level `switch` branch.

Both branch-contained forms permit multiple generated spawns on same-body
`await_all` and multi-pending `await_any` only as an observation point before
a mandatory same-body `await_all` drain.

The top-level `when` body and top-level `switch` branch forms also permit the
documented local plain `(do child)` while generated nested spawns are pending
before a later same-body `await_all` drain; both branch-contained forms also
permit that local do after a prior multi-pending `await_any` observation.
Both branch-contained forms also permit that local do to be followed by
additional generated nested `spawn` sites before the same later `await_all`
drain, either when no multi-pending `await_any` observation is active before
the later spawn or after the local `do` follows a prior multi-pending
observation. In the prior-observation form, a second post-spawn
multi-pending `await_any` may run before the mandatory same-body `await_all`;
both observations leave the outstanding generated-spawn done set live for the
final drain.

Both branch-contained forms also permit the documented plain generated-child
`(do child)` while generated nested spawns are pending before that same later
drain.
Both branch-contained forms also permit that plain generated-child do to be
followed by additional generated nested `spawn` sites before the same later
`await_all` drain, either when no multi-pending `await_any` observation is
active before the later spawn or after the generated-child `do` follows a
prior multi-pending observation. That same plain generated-child do-then-spawn
shape may also run a post-spawn multi-pending `await_any` observation before
the final drain in either branch: when no prior multi-pending observation is
active before the later spawn, or after the generated-child `do` follows a
prior multi-pending observation. Both `await_any` observations leave the
outstanding generated-spawn done set live for the final drain.

The top-level `when` body and top-level `switch` branch nested repeat
generated-child `(do child)` subsets also permit a prior multi-pending
`await_any` observation while generated nested spawns remain pending,
provided the later same-body `await_all` drain still gates nested repeat
re-entry on every outstanding generated child.

Both branch-contained forms also permit plain generated-child `(do child)`
before a post-do multi-pending `await_any` observation while generated nested
spawns remain pending, provided that the later same-body `await_all` drain
still gates nested repeat re-entry on every outstanding generated child.

Both branch-contained static-parameter generated `(do child (params ...))`
subsets also permit that generated do before a post-do multi-pending
`await_any` observation while generated nested spawns remain pending,
provided that the generated do instance completes before the observation and
the later same-body `await_all` drain still gates nested repeat re-entry on
every outstanding generated child.

Both branch-contained forms also permit documented static-parameter bound
generated `(do child (params ...) (bind ...))` while generated nested spawns
are pending before that same later drain. Both branch-contained forms also
permit that bound generated do before a post-do multi-pending `await_any`
observation while wiring the generated-top input/output binding handoffs for
the generated do instance.

Both branch-contained forms also permit documented static-parameter generated
`(do child (params ...))` while generated nested spawns are pending before
that same later drain.

Both branch-contained static-parameter generated subsets also permit a prior
multi-pending `await_any` observation before that generated do, with the same
later `await_all` drain requirement.

The shipped repeat-body local `(do child)` subset and the shipped
when-contained and switch-contained repeat local/generated `do` exceptions
apply only to their documented repeat placements, not to repeats nested under
`while` or `until`.

Body clauses must be non-empty list forms.

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
behavior. Division and modulo inside the RHS reject literal-zero,
actor-constant-zero, actor-parameter-zero, and
same-transaction-parameter-zero divisor operands before scheduled `.fsm`
emission. Dynamic scalar divisors and nonzero same-transaction parameter
divisors lower unchanged; full runtime nonzero proof is still backlog.

Shift operations are also exact scalar forms:
`(shift_left reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` and
`(shift_right reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])`.

The optional width value can be a positive literal, same-transaction scalar
parameter default on a generated child or direct/non-generated transaction,
actor-local scalar parameter default, declared actor constant, or qualified
imported package scalar constant that resolves to a positive integer.
`assemble` and `extract` use the same source set in ordered
`(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)` lists. Unrelated or
cross-transaction parameters remain fail-closed for this data-width surface.

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
must be a positive integer literal, a declared positive actor constant, an
actor-local scalar parameter default, a same-transaction scalar parameter
default, or a qualified imported package scalar constant that resolves to a
positive integer. Each option may appear at most once, and `min` must be less
than or equal to `max` when both are present. Accepted symbolic bounds resolve
before counter emission; the generated `.fsm` guard and timeout checks contain
the resolved integer. Same-transaction parameters shadow actor-level static
names and remain local lowering inputs. A valid explicit `max` bound drives
the generated counter width and max violation check; omitted bounds use
scheduler defaults. Unknown or unqualified package constants, aggregate
package constants, package member/item paths, cross-transaction parameters,
runtime signals, arbitrary expressions, zero-valued constants, and
zero-valued or non-scalar actor/transaction parameters fail closed.
Generated child activation overrides for latency-bound transaction parameters
must preserve the child default value; mismatches fail closed until
per-activation latency counter specialization is shipped. The rejected
shape is a rule-trigger activation whose child default `(params (LAT N))`
feeds a `(latency (min LAT) (max LAT))` clause, when the activation site
passes a different value:

```text
(transaction worker
  (params
    (LAT 4))                 ;; child default drives the latency window
  (latency (min LAT) (max LAT))
  (complete done))
(rule launch fire
  (trigger worker
    (params
      (LAT 2))))             ;; <-- override mismatches the default
```

The validator emits
`Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides
latency-bound parameter 'LAT' on child 'worker'; activation-site
parameter override-specialized latency bounds remain deferred`. The
deferred lane is per-activation latency counter specialization.

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
| `(shift_left reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` | 1 | Flopped assignment |
| `(latency (min N) (max M))` | 0 | Verification logic only |
