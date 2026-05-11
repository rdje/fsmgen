# Intent Scheduling Format (`.isf`) — Specification v0.1

This is the initial format specification for the Intent Scheduling Format
(`.isf`), the hardware-intent layer above cycle-accurate `.fsm`.

Source material: [docs/INTENT_SCHEDULING_BRAINSTORM.md](INTENT_SCHEDULING_BRAINSTORM.md)

## 1. Purpose and positioning

The `.isf` format sits between SPECFORGE's IntentIR and FSMGen's `.fsm`:

```
PDF/spec -> SPECFORGE IntentIR -> .isf -> scheduled .fsm -> SV/VHDL
```

`.isf` is hardware-native and Lisp-ish, but not manually cycle-scheduled.
The author describes what should happen (transactions, rules, handshakes,
phases, constraints); the FSMGen scheduler infers when (states, cycles,
enables) and produces an explicit scheduled `.fsm` plus a schedule report.

Cycles are not hidden. They become an inferred, scheduled, and reviewable
compiler result.

## 2. File extension and root form

- Extension: `.isf`
- Root form: `(?actor:actor_name ...)` — an actor is the top-level unit of
  intent scheduling. It describes one hardware agent (requester, completer,
  channel, pipeline stage, etc.) through a collection of transactions, rules,
  phases, and resources.

## 3. Core constructs

### 3.1 Actor declaration

```lisp
(?actor:ahb_requester
  (+system (clock clk) (areset rst_n))

  ;; ports: interface to the outside
  (+ports
    (in  cmd_valid 1) (out cmd_ready 1)
    (in  cmd_addr 32) (in  cmd_write 1)
    (out HADDR 32) (out HWRITE 1) (out HTRANS 2)
    (in  HREADY 1) (in  HRDATA 32) (out HWDATA 32))

  ;; persistent state registers
  (+state
    (addr 32)
    (remaining_beats 8)
    (read_data 32))

  ;; transactions, rules, phases...
  ...
)
```

### 3.2 Transaction

A transaction describes one complete behavioral unit — a read burst, a write
transfer, a handshake sequence. The scheduler lowers it into an explicit FSM
state sequence.

```lisp
(transaction read_burst
  (accept cmd_valid cmd_ready)
  (request bus)
  (drive address_phase
    HADDR  = cmd_addr
    HWRITE = 0
    HTRANS = NONSEQ)
  (repeat remaining_beats
    (await HREADY)
    (capture HRDATA -> read_data))
  (complete done))
```

**Transaction clauses:**

| Clause | Meaning | Lowering |
|--------|---------|----------|
| `(accept sig1 sig2 ...)` | Wait for handshake; consume input | State with `sig1 && sig2` guard |
| `(request resource)` | Acquire shared resource | State that asserts request, waits for grant |
| `(drive phase_name body...)` | Named output phase | State that drives listed signals |
| `(repeat count body...)` | Loop `count` times | Counter register + loop-back state |
| `(await signal)` | Stall until signal | State with `!signal` self-loop |
| `(capture signal -> register)` | Sample signal into register | Assignment on transition |
| `(complete signal)` | Assert completion, return to wait | Pulse done, go to accept/idle |

### 3.3 Rule

A rule is an atomic guarded action — closer to hardware rule semantics than
to software conditionals. Multiple rules on the same target must be proven
mutually exclusive or explicitly prioritized by the scheduler.

```lisp
(rule accept_cmd
  (when (and cmd_valid cmd_ready))
  (set active_addr cmd_addr)
  (set active_write cmd_write)
  (start address_phase))
```

**Rule clauses:**

| Clause | Meaning |
|--------|---------|
| `(when condition)` | Guard expression |
| `(set register value)` | Synchronous assignment |
| `(start transaction)` | Trigger a transaction's state machine |
| `(assert signal)` | Drive a signal combinatorially |
| `(pulse signal)` | Drive a signal for exactly one cycle |

### 3.4 Phase

A named phase within a transaction or actor. Phases can be sequenced,
repeated, or conditionally branched.

```lisp
(phase address_phase
  (outputs HADDR HWRITE HTRANS)
  (next data_phase))

(phase data_phase
  (await HREADY)
  (on HREADY (next complete_phase)))
```

### 3.5 Handshake

A handshake is the fundamental hardware synchronization primitive:
valid/ready, request/grant, or custom signal pairs.

```lisp
(handshake cmd
  (valid cmd_valid)
  (ready cmd_ready))

(handshake bus_request
  (valid HBUSREQ)
  (ready HGRANT))
```

### 3.6 Resource declaration

Resources model shared hardware that can only be used by one actor/transaction
at a time. The scheduler enforces mutual exclusion.

```lisp
(+resources
  (resource bus (arbiter priority))
  (resource memory_port (arbiter round_robin)))
```

### 3.7 Latency constraint

Declare expected or maximum latency for a phase or transaction.

```lisp
(transaction read_burst
  (latency min 2 max 8)
  ...)
```

If the scheduler cannot meet the constraint, it must fail with an actionable
report.

### 3.8 Pipeline stage

A streaming stage with implicit valid/ready handshake.

```lisp
(stage crc_update
  (input byte_stream)
  (output crc_stream)
  (latency <= 3)
  (compute
    (set crc (crc_next crc input_byte))))
```

## 4. Lowering contract

### 4.1 Transaction → FSM states

Each transaction becomes an FSM sub-machine:

```
transaction read_burst
  -> states: read_burst_idle, read_burst_addr, read_burst_data,
             read_burst_done
  -> transitions: driven by accepts, awaits, repeats, completes
  -> outputs: muxed through the active transaction's state
```

### 4.2 Phase → FSM state

Each phase becomes one or more FSM states:

```
phase address_phase
  -> state: address_phase
  -> outputs: HADDR, HWRITE, HTRANS driven combinatorially from state
```

### 4.3 Rule → FSM guard + action

Each rule maps to a conditional assignment block within the FSM state
that evaluates its guard:

```
(rule accept_cmd (when ...) (set ...) (start ...))
  -> if (condition) in current state: set register, trigger sub-FSM
```

### 4.4 Schedule report

Every `.isf` compilation produces a schedule report alongside the `.fsm`:

```json
{
  "source": "ahb_requester.isf",
  "scheduled_fsm": "ahb_requester.fsm",
  "transactions": [
    {
      "name": "read_burst",
      "states": ["read_burst_idle", "read_burst_addr", "read_burst_data", "read_burst_done"],
      "inferred_counter": "remaining_beats",
      "max_latency": 8
    }
  ],
  "resource_arbitration": {
    "bus": "priority"
  },
  "ambiguities": [],
  "fidelity": "full"
}
```

## 5. Error and ambiguity reporting

When the scheduler cannot determine one safe schedule:

- **Ambiguous guard ordering**: two rules may fire simultaneously on the same
  target → report the conflicting rules, suggest explicit `(priority ...)`
  declaration.
- **Unmet latency constraint**: required latency is impossible with the given
  resource model → report the constraint, the computed latency, and the
  bottleneck.
- **Unresolved resource conflict**: two transactions need the same resource
  without declared arbitration → report the conflict, suggest arbiter type.

## 6. Relationship to `.fsm`

`.isf` lowers deterministically to `.fsm`. The generated `.fsm`:

- Uses the same `?fsm:name` root form
- Uses explicit state DTs with transitions
- Preserves signal names and widths from the `.isf` source
- Carries provenance comments mapping `.fsm` states back to `.isf` constructs
- Is valid for strict-mode compilation through the existing pipeline

## 7. What this specification does NOT yet cover

- Multi-actor composition (multi-`.isf` to shared `.fsm` top)
- Pipelined transaction overlap
- Speculative execution / branch prediction semantics
- Power/clock-gating intent
- Formal property generation from contracts
- The full `.isf` parser implementation

## 8. Open design questions

1. Should `(repeat ...)` support dynamic count expressions, or only
   compile-time constants and register values?
2. How should nested transactions compose — flatten to one FSM, or generate
   hierarchical sub-FSMs?
3. Should `(rule ...)` support `(priority ...)` declarations inline, or
   should priority be a separate section?
4. What is the concrete syntax for `(contract ...)` temporal assertions?
5. How should the scheduler handle `(await ...)` on signals that are outputs
   of another transaction — deadlock detection, or assume external?

These will be resolved through implementation feedback and SPECFORGE
integration requirements.
