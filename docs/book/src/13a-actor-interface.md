# Actor and Interface

## Actor Declaration

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)
  ...)
```

Every actor has a clock, an optional reset, and optional watchdog.
The actor is the top-level unit — one hardware agent.

The parser treats `(clock ...)`, `(reset ...)`, `(watchdog ...)`,
`(interface ...)`, and `(storage ...)` as singleton actor clauses. Each may
appear at most once in an actor; repeated clauses are rejected before the
public actor shell is returned rather than merged or overwritten.

## Clock

```lisp
(clock clk)
```

Single clock per actor. No multi-clock support yet.

## Reset

```lisp
(reset rst_n)                          ;; sync, polarity from _n → active_low
(reset (rst_n))                        ;; sync, polarity from _n
(reset (rst_n async))                  ;; async, polarity from _n
(reset (rst_n async active_low))       ;; explicit
(reset rst)                            ;; sync, active_high (no _n suffix)
```

Reset name convention: `*_n` or `*_b` suffix → `active_low`. Otherwise `active_high`.

**Lowering to .fsm**:
| ISF | .fsm |
|-----|------|
| `(reset (rst_n async active_low))` | `(areset rst_n)` |
| `(reset (rst async))` | `(areset rst)` |
| `(reset rst_n)` | `(sreset rst_n)` |

## Watchdog

```lisp
(watchdog 65536)
```

Global timeout for every `(await ...)` in this actor.
See [Transactions](13b-transactions.md) for per-await semantics.

**Counter width** is inferred from the limit by the current scheduler.

## Interface

```lisp
(interface
  (input  start)                  ;; default width 1
  (input  addr  (width 32))       ;; explicit width
  (output done)                   ;; default width 1
  (output rdata (width 32))
  (output PADDR (width 32)))
```

Ports become `.fsm` `+size` declarations and module ports. Inferred scheduler
storage is not emitted a second time when it shares a name with a declared port.
Interface port names are unique across both input and output directions, and
the interface block itself is a singleton actor clause.

## Actor-Owned Storage

```lisp
(storage
  (var rd_ptr (width 2))
  (variable wr_ptr (width 2))
  (state occupancy (width 3))
  (bank data (width 8) (depth 4)))
```

The shipped actor-owned storage forms are fixed-width internal scalar
variables and fixed-depth banks. The preferred scalar spelling is
`(var name (width N))`; `(variable ...)` and the older `(state ...)` spelling
are accepted aliases that normalize to the same scalar storage kind. A scalar
entry lowers to one internal storage signal with the authored name. A bank
lowers to deterministic scalar element names in the scheduled `.fsm` review
artifact: `data_0`, `data_1`, `data_2`, and `data_3` for the example above.

This scalarized representation is deliberate for the first reusable FIFO work.
It lets the `DEPTH=4` fixture use four concrete storage entries, 2-bit
pointers, and 3-bit occupancy state while staying on the existing scalar
signal/flop backend path. Parameter-derived widths/depths, symbolic
dimensions, and memory-array backend emission are future generalizations.
Pointer-selected access is available through explicit action forms such as
`(store data wr_ptr data_in)` and `(load data rd_ptr as data_out)`, which
lower through guarded scalarized entries.

`(storage ...)` is a singleton actor clause. Storage names and scalarized
element names must not collide with interface ports, actor clock/reset signals,
or generated scheduler signals such as `can_accept`. Missing `(width N)`,
missing bank `(depth N)`, duplicate storage names, duplicate scalarized element
names, and repeated storage clauses fail closed before scheduler handoff.

Declared storage is emitted in scheduled `.fsm` `+size`, contributes width
evidence to later lowering, and appears in schedule reports as `kind:
register`, `role: actor_storage`, with positive integer `width`. Used storage
signals reach SystemVerilog through the normal scalar assignment path.
The report `kind` is the generated storage class; authored scalar storage uses
the normalized scalar storage kind, and `(register ...)` is not an accepted
storage entry spelling.

### Complete Example — APB Interface

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65536)

  (interface
    ;; Local side
    (input  start)
    (input  req_write)
    (input  req_addr  (width 32))
    (input  req_wdata (width 32))
    (output done)
    (output last_read_data (width 32))
    (output last_error)
    ;; APB bus side
    (output PADDR   (width 32))
    (output PWRITE)
    (output PWDATA  (width 32))
    (output PSEL)
    (output PENABLE)
    (input  PREADY)
    (input  PRDATA  (width 32))
    (input  PSLVERR))
  ...)
```

**Generated .fsm**:
```lisp
(?fsm:apb_requester
  (+system (clock clk) (areset rst_n))
  (+size
    (start 1) (req_write 1) (req_addr 32) (req_wdata 32)
    (done 1) (last_read_data 32) (last_error 1)
    (PADDR 32) (PWRITE 1) (PWDATA 32)
    (PSEL 1) (PENABLE 1) (PREADY 1) (PRDATA 32) (PSLVERR 1)
    ...)
  ...)
```

## Implicit Signals

These are auto-generated by the scheduler:

| Signal | Width | Purpose |
|--------|-------|---------|
| `can_accept` | 1 | Combinational: `1` in idle, `0` elsewhere |
| `{drive}_start` | 1 | Asserted by drive calls to enable the drive non-state DT |
| `{drive}_{param}` | 1 | Per-parameter signal, wired to actual value |
| `{transaction}_cnt` | inferred | Repeat counter |
| `{transaction}_wd` | inferred | Watchdog counter |
| `{transaction}_cc` | inferred | Latency cycle counter |
