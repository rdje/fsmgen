# Intent Scheduling Format (`.isf`)

The Intent Scheduling Format is a higher-level, cycle-abstracted hardware
description layer above `.fsm`. Where `.fsm` requires explicit cycle-by-cycle
state authoring, `.isf` lets you describe what should happen — transactions,
handshakes, rules — and the compiler schedules the cycles.

```text
.isf → scheduled .fsm → SystemVerilog / VHDL
```

## Quick Example

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)

  (interface
    (input  start)
    (output done)
    (input  req_addr  (width 32))
    (output PADDR   (width 32))
    (input  PREADY))

  ;; Drive definitions — combinational blocks
  (drive (psel val)   (PSEL val))
  (drive (penable val) (PENABLE val))

  (drive setup_phase
    (PADDR addr)
    (PSEL 1)
    (PENABLE 0))

  (transaction apb_transfer
    (on start
      (sample req_addr as addr))
    (drive setup_phase)
    (drive penable 1)
    (await PREADY)
    (complete done)
    (latency (min 2) (max 16))))
```

## Core Concepts

### Actor

An actor is the top-level unit. It contains:

- **Clock and reset**: `(clock clk)`, `(reset (rst_n async active_low))`
- **Interface**: `(input ...)`, `(output ...)` with optional `(width N)`
- **Watchdog**: global timeout for all `(await ...)` clauses
- **Drive definitions**: combinational output blocks
- **Transactions**: cycle-scheduled behavioral sequences

### Transactions

A transaction describes one complete behavioral unit. The scheduler lowers
it to an explicit FSM state sequence.

| Clause | Meaning | Cycle |
|--------|---------|-------|
| `(on port body...)` | Activate when `port` is true and actor can accept | Entry |
| `(sample port as name)` | Capture port value as a named variable | Mid-transaction |
| `(drive name args...)` | Fire a combinational drive block | **1 cycle** |
| `(await port)` | Stall until `port` is true, with watchdog | Variable |
| `(repeat N body...)` | Loop `N` times | N × body cycles |
| `(when cond body...)` | Conditional branch | Branch |
| `(switch sig (val body...)...)` | Multi-way dispatch | Branch |
| `(complete port)` | Signal completion and return to idle | 1 cycle |
| `(latency (min N) (max M))` | Timing constraint | Compile-time check |

### Drive Blocks

Drives are combinational DT blocks. They fire when their `_start` signal
is asserted:

```lisp
;; Definition
(drive (scl val)        ;; parameterized — accepts one argument
  (scl val))            ;; drives scl to the passed value

;; Calls — each is one cycle
(drive scl 1)           ;; cycle N: scl = 1
(drive scl 0)           ;; cycle N+1: scl = 0
```

Parameterized drives accept formal parameters. Calls wire actual values
to input signals. Non-parameterized drives can have multiple assignments
that all fire in the same cycle:

```lisp
(drive start_condition  ;; all assignments same cycle
  (scl 1)
  (sda_out 0))
```

### Composition

Transactions can compose other transactions:

- `(do child)` — blocking call, reuses one instance
- `(spawn child as name)` — non-blocking fork, new instance per spawn
- `(await_all port)` — wait for all spawned children
- `(await_any port)` — wait for any spawned child

### Branching

```lisp
(when (> counter 0)
  (drive inc))
(when (= counter 0)
  (drive reset_phase))

(switch opcode
  (0 (drive read))
  (1 (drive write))
  (2 (drive error)))
```

### Control Flow

One drive call = one cycle. No magic merging. Concurrent actions go in
the same drive definition:

```lisp
;; These execute in consecutive cycles:
(drive scl 1)
(drive sda_out 0)

;; To do both in one cycle, define a combined drive:
(drive start_condition
  (scl 1)
  (sda_out 0))
(drive start_condition)  ;; executes both in one cycle
```

### Generated Output

The scheduler produces:

- **`.fsm` files**: explicit cycle-accurate FSM
- **Schedule report** (JSON): inferred states, storage, timing
- **SystemVerilog**: through the existing `.fsm` pipeline

### Current Limitations

- `(spawn ...)` composition generates per-instance signals but full
  multi-module `?top` composition is in progress
- Merge optimization for adjacent drive calls on non-conflicting ports
  is deferred
- `(contract ...)` temporal assertions not yet implemented
