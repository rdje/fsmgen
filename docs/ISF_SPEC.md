# Intent Scheduling Format (`.isf`) — Specification v0.2

This is the format specification for the Intent Scheduling Format
(`.isf`), the hardware-intent layer above cycle-accurate `.fsm`.

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

Cycles are not hidden. They become an inferred, scheduled, and reviewable
compiler result. Storage (register vs wire) is also a scheduler decision —
the `.isf` author expresses intent, not hardware.

**Design principles:**
- Pure Lisp syntax: no `(+...)` forms, no keyword arguments, no `:width`
- Port-level thinking: the author sees the module interface, not internal
  wires or registers
- Handshakes as first-class named abstractions: `(on handshake)`, not
  `(accept sig1 sig2)`
- Intent-level vocabulary: `(assign ...)`, `(sample ...)`, `(drive ...)` —
  never `(set register)` or `(capture -> register)`

## 2. File extension and root form

- Extension: `.isf`
- Root form: `(?actor:actor_name ...)` — an actor is the top-level unit of
  intent scheduling. One hardware agent (requester, completer, channel,
  pipeline stage).

## 3. Core constructs

### 3.1 Actor declaration

```lisp
(?actor:ahb_requester
  (clock clk)
  (reset rst_n (async) (active_low))

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

  (transaction read_burst
    (on cmd
      (sample cmd_addr  as active_addr)
      (sample cmd_write as active_write))
    (drive address_phase
      (assign HADDR  active_addr)
      (assign HWRITE 0)
      (assign HTRANS NONSEQ))
    (repeat remaining_beats
      (await HREADY)
      (sample HRDATA as beat_data))
    (complete done)
    (latency (min 2) (max 8)))

  (resources
    (resource bus (arbiter priority))))
```

### 3.2 Interface

Ports are declared with direction, name, and optional properties.

```lisp
(interface
  (input  name)
  (input  name  (width N))
  (output name)
  (output name  (width N)))
```

Default width is 1. The `(width N)` form is the only property currently
defined; future properties (e.g. `(signed)`, `(enum ...)`) are deferred.

### 3.3 Clock and reset

```lisp
(clock name)                                     ;; synchronous clock
(reset name)                                     ;; synchronous active-high reset
(reset name (async))                             ;; asynchronous active-high
(reset name (async) (active_low))                ;; asynchronous active-low
```

Every actor must declare exactly one clock and may declare zero or one reset.

### 3.4 Handshake

A handshake names a valid/ready port pair. It becomes the activation
mechanism for transactions.

```lisp
(handshake name
  (valid port_name)
  (ready port_name))
```

Only output ports may be used as `ready`. Only input ports may be used as
`valid`. Handshakes are actor-local; cross-actor handshakes are deferred.

### 3.5 Transaction

A transaction describes one complete behavioral unit. The scheduler lowers
it to an explicit FSM state sequence.

```lisp
(transaction name
  clause...
  clause...)
```

**Transaction clauses:**

| Clause | Meaning |
|--------|---------|
| `(on handshake body...)` | Activate when handshake fires. Bind input values. |
| `(when condition body...)` | Activate when arbitrary condition is true. No automatic value binding. |
| `(drive phase_name body...)` | Named output phase. Body contains `(assign ...)` forms. |
| `(repeat count body...)` | Loop `count` times. Count must be a compile-time constant. |
| `(await port)` | Stall until port is true. Port must be an input. |
| `(sample port as name)` | At this point in the transaction, capture the port value and make it available as `name` for the rest of the transaction. Scheduler decides storage. |
| `(assign port value)` | Drive an output port. Value may be a literal, a bound name, or an expression. |
| `(complete port)` | Assert completion. Port is pulsed for one cycle. Transaction returns to idle. |
| `(latency (min N) (max M))` | Declare timing bounds. Scheduler fails if impossible. |

**Example — AHB read burst:**

```lisp
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
```

### 3.6 Rule

A rule is an atomic guarded action. Multiple rules targeting the same
output must be proven mutually exclusive or explicitly prioritized.

```lisp
(rule name
  (when condition)
  action...)
```

**Rule actions:**

| Action | Meaning |
|--------|---------|
| `(assign port value)` | Drive an output when the rule fires |
| `(trigger transaction)` | Start a transaction's state machine |
| `(assert port)` | Drive a port combinatorially while the rule holds |
| `(pulse port)` | Drive a port for exactly one cycle when the rule fires |

Rules are evaluated continuously. The scheduler emits combinational or
synchronous logic as needed to meet the semantics.

### 3.7 Phase

A named phase within a transaction. Phases sequence explicitly.

```lisp
(phase name
  (outputs port...)
  (next phase_name))

(phase name
  (await port)
  (on port (next phase_name)))
```

Phases are optional sugar. A transaction can use inline `(drive ...)` and
`(await ...)` instead.

### 3.8 Pipeline stage

A streaming stage with implicit valid/ready handshake on its input and
output ports.

```lisp
(stage name
  (input  port)
  (output port)
  (latency (max N))
  (compute
    (assign output (expression input))))
```

The scheduler generates the full valid/ready plumbing and any pipeline
registers needed to meet the latency constraint.

### 3.9 Resources

Shared hardware that only one transaction can use at a time.

```lisp
(resources
  (resource name (arbiter type)))
```

Arbiter types: `priority`, `round_robin`. A transaction acquires a resource
with `(request name)` inside its body. The scheduler serializes access.

## 4. Lowering contract

### 4.1 Transaction → FSM

The scheduler assigns one FSM state per transaction phase:

```
(read_burst
  (on cmd ...)        -> state: read_burst_wait_cmd
  (drive address ...) -> state: read_burst_address
  (repeat N (await HREADY) (sample HRDATA ...))
                      -> states: read_burst_data_0 .. read_burst_data_N-1
                         + counter register: read_burst_beat_count
  (complete done)     -> state: read_burst_done
```

### 4.2 Storage inference

`(sample port as name)` does not specify hardware. The scheduler decides:

- If `name` is used only within the same phase: wire
- If `name` is used in a later phase: register (value must persist)
- If `name` is used in multiple phases with different sources: register
  with muxed input

The schedule report records every storage decision.

### 4.3 Handshake → FSM guard

`(on handshake (sample ...) ...)` lowers to a state transition guarded by
`valid && ready`, with the bound port values sampled on that transition.

### 4.4 Schedule report

Every `.isf` compilation produces:

```json
{
  "source": "ahb_requester.isf",
  "scheduled_fsm": "ahb_requester.fsm",
  "transactions": [
    {
      "name": "read_burst",
      "states": ["wait_cmd", "address", "data_0", "data_1", "done"],
      "inferred_storage": {
        "active_addr":  {"kind": "register", "width": 32},
        "beat_data":    {"kind": "register", "width": 32},
        "beat_count":   {"kind": "counter",  "width": 8}
      },
      "latency": {"min": 2, "max": 8, "met": true}
    }
  ],
  "resource_arbitration": {"bus": "priority"},
  "ambiguities": [],
  "fidelity": "full"
}
```

## 5. Error and ambiguity reporting

| Situation | Scheduler response |
|-----------|-------------------|
| Two rules may fire on the same output | Report conflicting rules; suggest `(priority ...)` |
| Latency constraint cannot be met | Report required vs computed latency |
| Resource conflict without arbiter | Report conflict; suggest arbiter type |
| `(sample ...)` used with no source in scope | Report undefined binding |
| `(await ...)` on an output port | Report direction error |
| Handshake uses wrong-direction port | Report `valid` must be input, `ready` must be output |

## 6. Relationship to `.fsm`

`.isf` lowers deterministically to `.fsm`. The generated `.fsm`:

- Uses `?fsm:name` root form
- Contains explicit state DTs with transitions, assignments, and enables
- Preserves port names and widths from the `.isf` source
- Carries provenance comments mapping `.fsm` states back to `.isf` constructs
- Passes strict-mode compilation through the existing pipeline
- Is human-inspectable and patchable

## 7. What this specification does NOT yet cover

- Multi-actor composition (multi-`.isf` to shared `.fsm` top)
- Transaction nesting or hierarchy
- Pipelined/concurrent transaction execution
- `(contract ...)` temporal assertions
- `(priority ...)` rule ordering section
- Speculative or out-of-order execution
- Power/clock-gating intent
- The `.isf` parser implementation

## 8. Open design questions

1. Should `(repeat ...)` support dynamic count from a bound name, or only
   compile-time constants?
2. How should nested transactions compose — flatten to one FSM, or generate
   hierarchical sub-FSMs?
3. Should `(priority ...)` be a separate section, inline in rules, or both?
4. What is the concrete syntax for `(contract ...)` temporal assertions?
5. How should the scheduler detect deadlocks when one transaction `(await ...)`
   a port that is driven by another transaction's `(complete ...)`?
6. Should `(sample ... as ...)` be allowed outside `(on handshake ...)` —
   e.g., `(sample HRDATA as beat_data)` immediately after `(await HREADY)`?
7. Should the scheduler infer the need for a counter from `(repeat N ...)`
   without the author declaring it, or should the author declare the
   counter explicitly?

These will be resolved through implementation feedback and SPECFORGE
integration requirements.
