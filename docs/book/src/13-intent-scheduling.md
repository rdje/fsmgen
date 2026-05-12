# Intent Scheduling Format (`.isf`)

The Intent Scheduling Format abstracts cycle counting away from the author.
You describe **what** happens — the compiler infers **when** and produces
explicit cycle-accurate `.fsm`.

```text
.isf → LoweringIR → Emitter::FSM → .fsm → SystemVerilog / Verilog
                    → Emitter::JSON → Schedule Report
```

## Design Principles

- **No register vocabulary**. You work with variables, ports, and expressions.
  The scheduler decides storage class (wire, flop, counter).
- **No magic merging**. One `(drive ...)` = one cycle. Timing is predictable.
- **Handshake-free activation**. `(on port)` fires when the port is true AND
  the actor can accept. The ready side (`can_accept`) is implicit.
- **Variables are first-class**. `(sample ...)`, `(update ...)` — just like
  programming language variables. The scheduler handles persistence.
- **Compile-time issues are explicit**. Parser and lowering failures are raised,
  and the schedule report carries a `compile_issues` field. Broader conflict,
  deadlock, and resource diagnostics are still being expanded.

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

  (drive (psel val)   (PSEL val))
  (drive (penable val) (PENABLE val))

  (transaction apb_transfer
    (on start
      (sample req_addr as addr))
    (drive setup_phase)
    (drive penable 1)
    (await PREADY)
    (complete done)
    (latency (min 2) (max 16))))
```

## Pipeline

```
ISF Source (.isf)
    │
    ▼
FSM::Adapter::ISF     ← Lispish parser
    │
    ▼
FSM::Scheduler::ISF::LoweringIR   ← typed IR
    │
    ├──► Emitter::FSM   → .fsm text → fsmgen → SystemVerilog
    └──► Emitter::JSON  → schedule report
```

The schedule report is generated from the same IR as the `.fsm` text. The
current APB report shape is regression-covered, but the JSON schema remains a
current implementation surface rather than a frozen external API. Assigned
scheduler counters in the `*_wd`, `*_cc`, and `*_cnt` naming families are
reported as `counter` storage with the width inferred by the lowering IR.
Transaction summaries include the generated state families used by the current
scheduler, including control-flow and data-operation states.

## Current Limitations

- `(do ...)` and `(spawn ...)` bind named start/done signals in scheduled
  `.fsm`; composition-top instantiation and spawn parameter binding remain
  deferred.
- `(resources ...)` and `(priority ...)` are parsed but not enforced as
  arbitration policy.
- `(shift_right ...)` field-width parameter is not yet configurable.
- `(extract ...)` field slice ranges are placeholder names, not exact slices.
- `(contract ...)` temporal assertions are not implemented.
