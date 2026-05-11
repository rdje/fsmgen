# Intent Scheduling Format (`.isf`) — Specification v0.3

Source material: [docs/INTENT_SCHEDULING_BRAINSTORM.md](INTENT_SCHEDULING_BRAINSTORM.md)

## 1. Purpose and positioning

```
PDF/spec -> SPECFORGE IntentIR -> .isf -> scheduled .fsm -> SV/VHDL
```

`.isf` is hardware-native and Lisp-ish, but not manually cycle-scheduled.
The author describes what should happen (transactions, handshakes, phases,
rules, constraints); the FSMGen scheduler infers when (states, cycles,
enables, storage) and produces an explicit scheduled `.fsm` plus a schedule
report.

**Design principles:**
- Pure Lisp syntax: no `(+...)` forms, no keyword arguments, no `:width`
- Port-level thinking: the author sees the module interface
- Handshakes as first-class named abstractions
- Intent-level vocabulary: `(sample ...)`, `(assign ...)`, `(drive ...)` —
  never `(set register)` or `(capture -> register)`
- Scheduler owns storage, counters, arbitration — author expresses intent
- Every compile-time detectable issue is reported, never silently resolved

## 2. File extension and root form

- Extension: `.isf`
- Root form: `(actor name ...)` — an actor is the top-level unit of intent
  scheduling. One hardware agent (requester, completer, channel, pipeline
  stage). No `?actor:name` form; that belongs to `.fsm`.

## 3. Core constructs

### 3.1 Actor declaration

```lisp
(actor ahb_requester
  (clock clk)
  (reset rst_n (async) (active_low))
  (watchdog 65536)

  (interface
    (input  cmd_valid)
    (output cmd_ready)
    (input  cmd_addr  (width 32))
    (input  cmd_write)
    (output HADDR     (width 32))
    (output HWRITE)
    (output HTRANS    (width 2))
    (input  HREADY)
    (input  HRDATA    (width 32))
    (output HWDATA    (width 32)))

  (handshake cmd
    (valid cmd_valid)
    (ready cmd_ready))

  (handshake data_beat
    (valid HREADY)
    (ready HTRANS))     ;; example only — real handshake mapping deferred

  (transaction read_burst
    (on cmd
      (sample cmd_addr  as active_addr)
      (sample cmd_write as active_write))
    (drive address_phase
      (assign HADDR  active_addr)
      (assign HWRITE 0)
      (assign HTRANS NONSEQ))
    (repeat beats
      (await HREADY)
      (sample HRDATA as beat_data))
    (complete done)
    (latency (min 2) (max 8)))

  ;; transaction composition: sequence
  (transaction read_then_write
    (do read_burst)
    (do write_burst)
    (complete done))

  ;; transaction composition: parallel spawn
  (transaction scatter_read
    (on cmd (sample cmd_addr as base))
    (spawn read_burst)
    (spawn read_burst)
    (spawn read_burst)
    (await_all done)
    (complete done))

  ;; resource arbitration
  (resources
    (resource bus (arbiter priority)))

  ;; rule priority
  (priority accept_cmd over reject_cmd))
```

### 3.2 Interface

```lisp
(interface
  (input  name)
  (input  name  (width N))
  (output name)
  (output name  (width N)))
```

Default width is 1. `(width N)` is the only property currently defined.

### 3.3 Clock, reset, and watchdog

```lisp
(clock name)
(reset name)
(reset name (async))
(reset name (async) (active_low))
(watchdog N)
```

`(watchdog N)` declares the default watchdog cycle count for all
`(await ...)` in the actor. Individual `(await port (watchdog M))`
overrides it per instance.

### 3.4 Handshake

A handshake names the valid port. The ready side is always the implicit
`can_accept` signal (combinational, asserted in idle, 0 elsewhere).

```lisp
(handshake name
  (valid port_name))
```

`valid` must be an input port. `(on name body...)` fires when `valid` is
1 AND `can_accept` is 1 (the actor is idle and a request is present).

### 3.5 Transaction

A transaction describes one complete behavioral unit. The scheduler lowers
it to an explicit FSM state sequence.

```lisp
(transaction name
  clause...
  clause...)
```

**Activation clauses:**

| Clause | Meaning |
|--------|---------|
| `(on handshake body...)` | Activate when handshake fires. Body typically contains `(sample ...)` to capture input values. |
| `(when condition body...)` | Activate when condition is true. No automatic value binding. |

**Body clauses:**

| Clause | Meaning |
|--------|---------|
| `(drive phase_name body...)` | Named output phase. Body: `(assign ...)` forms. |
| `(repeat count body...)` | Loop `count` times. `count` may be a literal integer, a bound name, or an arbitrary expression that evaluates to an integer. The scheduler infers a counter register — the author never declares one. |
| `(await port)` | Stall until port is true. Every `(await ...)` carries an implicit watchdog timer inherited from the actor's `(watchdog N)` declaration. The timeout may be overridden per-instance: `(await port (watchdog M))`. If the awaited condition does not hold before the watchdog expires, the transaction enters an error state and asserts a timeout indication. |
| `(sample port as name)` | Capture port value at this point. Scheduler decides storage (wire, register, mux). `name` is available for the rest of the transaction. Allowed anywhere in the transaction body: inside `(on ...)` for activation-time capture, or standalone for mid-transaction sampling (e.g. after `(await ...)`, inside `(repeat ...)`). |
| `(assign port value)` | Drive an output port. Value: literal, bound name, or expression. |
| `(complete port)` | Assert completion. Port is pulsed. Transaction returns to idle. |
| `(latency (min N) (max M))` | Timing bounds. Scheduler fails if impossible. |

### 3.6 Transaction composition

Transactions can be composed within an actor. Three composition forms:

#### 3.6.1 Sequence — `(do transaction)`

Blocking call. The calling transaction waits for the called transaction
to complete before continuing.

```lisp
(transaction read_then_write
  (on cmd (sample cmd_addr as addr))
  (do read_burst)
  (do write_burst)
  (complete done))
```

Semantics: `read_burst` runs to `(complete ...)`, then `write_burst` runs.
The calling transaction's state machine stalls during each `(do ...)`.

#### 3.6.2 Parallel spawn — `(spawn transaction)`

Non-blocking fork. The calling transaction launches the spawned transaction
and continues immediately without waiting. Multiple spawns may execute
concurrently (the scheduler serializes them onto cycles as needed).

Spawn may pass parameters and optionally name the spawned instance:

```lisp
(transaction scatter_read
  (on cmd (sample cmd_addr as base))
  (spawn read_burst as reader_0 (addr (+ base 0)))
  (spawn read_burst as reader_1 (addr (+ base 4)))
  (spawn read_burst              (addr (+ base 8)))  ;; anonymous
  (await_all done)
  (complete done))
```

Spawn semantics:
- Spawned transactions share the actor's interface and resources.
- Parameters are passed positionally to the spawned transaction's bound names.
- Spawned transactions may themselves `(spawn ...)` further transactions
  recursively. No explicit limit — the scheduler bounds state growth naturally.
- The scheduler resolves output conflicts through priority declarations.
- If two spawned transactions drive the same output port without a declared
  priority, the scheduler reports an error.

#### 3.6.3 Sync primitives

| Clause | Meaning |
|--------|---------|
| `(await_all port)` | Wait until every spawned transaction has completed (the named `port` has been pulsed by all of them). |
| `(await_any port)` | Wait until at least one spawned transaction has completed. |

The scheduler generates the necessary completion-tracking logic.

### 3.7 Rule

```lisp
(rule name
  (when condition)
  action...)
```

**Rule actions:**

| Action | Meaning |
|--------|---------|
| `(assign port value)` | Drive output when rule fires |
| `(trigger transaction)` | Start transaction's state machine |
| `(assert port)` | Drive combinatorially while rule holds |
| `(pulse port)` | Drive for exactly one cycle when rule fires |

### 3.8 Priority

Rule/transaction priority can be declared inline or as a separate section:

```lisp
;; Inline — inside a rule
(rule accept_cmd
  (priority over reject_cmd)
  (when (and cmd_valid cmd_ready))
  ...)

;; Separate section — references rules by name
(priority accept_cmd over reject_cmd)
(priority read_burst over write_burst)
```

### 3.9 Phase

Named phase, optional sugar for `(drive ...)`:

```lisp
(phase name
  (outputs port...)
  (next phase_name))
```

### 3.10 Pipeline stage

```lisp
(stage name
  (input  port)
  (output port)
  (latency (max N))
  (compute
    (assign output (expression input))))
```

### 3.11 Resources

```lisp
(resources
  (resource name (arbiter type)))
```

Arbiter types: `priority`, `round_robin`.

## 4. Lowering contract

The scheduler detects and reports every compile-time issue: deadlocks,
output conflicts, unmet latency constraints, direction errors, undefined
bindings. Nothing is silently resolved.

### 4.1 Transaction → FSM

States are named `{transaction}_{logical_phase}`:

```
read_burst:
  wait_cmd  -> address_phase  -> data_0..data_N-1  -> done
```

`(repeat N body)` lowers to a counter register + loop-back state. The
counter is inferred — the author never declares it.

`(do sub)` lowers to a nested sub-FSM call. The scheduler flattens the
combined state space.

`(spawn sub)` lowers to independent FSM instances. The scheduler arbitrates
shared outputs per declared priorities.

### 4.2 Storage inference

`(sample port as name)`: scheduler decides:
- Same-phase only usage → wire
- Cross-phase usage → register
- Multiple sources → register with mux

### 4.3 Schedule report

```json
{
  "source": "ahb_requester.isf",
  "transactions": [{
    "name": "read_burst",
    "states": ["wait_cmd", "address", "data_0", "done"],
    "inferred_storage": {
      "active_addr": {"kind": "register", "width": 32},
      "beat_data":   {"kind": "register", "width": 32},
      "beat_count":  {"kind": "counter",  "width": 8}
    },
    "latency": {"required": [2,8], "achieved": [2,8]}
  }],
  "composition": {
    "read_then_write": {"kind": "sequence", "of": ["read_burst","write_burst"]},
    "scatter_read":    {"kind": "parallel", "of": ["read_burst","read_burst","read_burst"]}
  },
  "compile_issues": []
}
```

## 5. What this specification does NOT yet cover

- Pipelined/concurrent execution of independent transactions within one actor
- `(contract ...)` temporal assertions (deferred to separate design discussion)
- Speculative or out-of-order execution
- Power/clock-gating intent
- The `.isf` parser implementation
- Watchdog timeout behavior per actor (error port, abort, skip)

## 6. Resolved design questions

1. `(sample ... as ...)` allowed both inside `(on ...)` (activation-time capture)
   and anywhere in the transaction body (mid-transaction sampling).
2. Every `(await ...)` carries an implicit watchdog timer. Watchdog cycle count
   is based on the actor's clock. A default is declared at the actor level;
   individual `(await ...)` instances may override it.
3. `(spawn ...)` supports parameter passing. Spawned transactions may recursively
   spawn further transactions with no explicit limit.
4. Spawned transaction instances may be anonymous (scheduler assigns a generated
   name like `read_burst_0`) or explicitly named by the author:
   `(spawn read_burst as reader_0)`. Both forms are allowed; named instances
   appear in the schedule report and debug output.
5. Cross-transaction deadlocks are not detected at compile time for now.
   Deadlocks are bounded by the implicit watchdog on every `(await ...)` —
   a deadlocked transaction eventually times out rather than locking up
   indefinitely.

## 7. Open design questions

1. What is the concrete syntax for `(contract ...)` temporal assertions?
   Deferred until we define the assertion types needed.
