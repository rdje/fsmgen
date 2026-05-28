# Cookbook

This chapter collects practical, copyable patterns.

## 1. A Small Counter FSM

```lisp
(?fsm:counter_demo
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (start 1)
    (done 1)
    (count 8)
  )
  (idle
    (<start
      (count <- 0)
      (done = 0)
      (-> run)
    )
  )
  (run
    (count <- (+ count 1))
    (<count=8'd15
      (done = 1)
      (-> idle)
    )
  )
)
```

Use this when you want:

- one clear state register
- one clear done pulse/flag
- a first debug target

## 2. A Standalone Routing DT

```lisp
(?dt:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
```

Use this when:

- the logic is mainly routing/selection
- you do not need named FSM states

## 3. One Generated Child Under A Top

```lisp
(?top:single_child_top
  (?fsmc:child child_ctrl_src)
)
```

Use this when:

- you want a top wrapper quickly
- the child interface can become the top interface honestly

## 4. Multi-Child Explicit Wiring

```lisp
(?top:two_child_top
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.final_data result_data)
  )
)
```

Use this when:

- child names do not all match top names
- you want explicit composition intent

## 5. Structural Actual Defaults

```lisp
(?top:uart_defaults_top
  (?ports:public_io
    default_data>8
    serial_out>
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    (=8'hA5 default_data)
    (=8'hA5 uart_tx.data_in)
    (=open uart_tx.enable)
    (uart_tx.serial_out serial_out)
  )
)
```

Use this when:

- one child input wants a fixed value
- one child input should remain intentionally open

## 6. Package-Backed Shared Values

```lisp
(?pkg:shared
  (+constants
    (RESET_BYTE 8'hA5)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1))
  )
)

(?fsm:uses_pkg
  (+import shared)
  (+size
    (OUT 8)
    (STATE_HIT 1)
  )
  (idle
    (OUT = shared.RESET_BYTE)
    (<MODE=shared.mode.BUSY
      (STATE_HIT = 1)
    )
  )
)
```

Use this when:

- several files should share the same named values
- you want semantics, not macros

## 7. Typed Aggregate Boundary

```lisp
(?top:typed_actual_top
  (+constants
    (FRAME
      (mode 2'b10)
      (flag 1))
  )
  (+types
    (type frame_t (record (mode (bits 2)) (flag bit)))
  )
  (?ports:public_io
    packed_out>frame_t
  )
  (?wiring:wiring
    /=FRAME/packed_out/
  )
)
```

Use this when:

- you want one named packed aggregate
- width alone is not the whole story

## 8. First Debug Run

```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log \
  --output /tmp/example.sv \
  fsm/lte_dif_pmaster.fsm
```

Use this when:

- generation succeeds but the emitted HDL looks suspicious
- a failure summary needs more local context

## 9. A Small ISF Actor

```lisp
(actor counter_actor
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction tick
    (on start)
    (wait 8)
    (complete done)))
```

Use this when:

- you want the minimum-viable ISF actor that compiles end-to-end
- you need a starting skeleton for `on` → body → `complete`
- you want to verify your toolchain on a one-transaction design

**Walkthrough.** `(actor counter_actor ...)` opens an ISF actor
named `counter_actor` — the unit of compilation that lowers to one
scheduled `.fsm` module. `(clock clk)` and `(reset rst_n)` declare
the actor's clock and reset polarity (the `_n` suffix is read as
active-low). `(interface ...)` enumerates the actor-level ports:
`(input start)` and `(output done)` are both one bit wide. The
single transaction `tick` has three clauses: `(on start)` says the
transaction entry waits for the input `start`; `(wait 8)` inserts an
eight-cycle wait before the next clause; `(complete done)` raises
the output port `done` and returns to idle.

## 10. Generated Child Via Spawn

```lisp
(actor spawn_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (complete done)))
```

Use this when:

- you want one parent transaction to activate a separate child
- the child can run on its own and signal back through `done`
- you need a generated-composition top in addition to the parent
  scheduled module

The `spawn` clause names the child instance (`w0`). The parent
waits with `await_all done` before completing.

**Walkthrough.** Two transactions live in this actor: `parent` and
`worker`. `worker` is a self-contained transaction that just
completes — by being referenced via `spawn`, the lowerer marks it
as a generated child and emits a separate `worker.fsm` plus a
composition top that wires `parent` and `worker` together.
`(spawn worker as w0)` is the activation site: it names the lexical
instance `w0` of the `worker` child in the generated top.
`(await_all done)` blocks the `parent` transaction until every
outstanding spawned child reports `done`. With one spawned
instance, that is equivalent to waiting for `w0.done`. The trailing
`(complete done)` then raises the actor's own `done` output.

## 11. Blocking Do Call With Parameter Override

```lisp
(actor do_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do worker
      (params (DELAY 4)))
    (complete done))
  (transaction worker
    (params (DELAY 4))
    (wait DELAY)
    (complete done)))
```

Use this when:

- you want a parameterized worker whose timing constants are
  authored once and passed through at the call site
- the parent should block until the child finishes (the `do`
  semantics)
- the call-site value matches the child default (mismatched
  overrides fail closed until per-activation specialization is
  shipped)

**Walkthrough.** `worker` is declared with `(params (DELAY 4))` —
a transaction-local scalar parameter whose default value is `4`.
The body uses it as `(wait DELAY)`, so the schedule sleeps for
`DELAY` cycles before completing. `parent` activates the worker
with `(do worker (params (DELAY 4)))`. The `(do ...)` form is a
blocking call: the parent state waits for the child's `done`
handoff before advancing. The activation-site `(params ...)`
override lists per-instance parameter values. The override value
`4` matches the child's declared default `4`, so this same-value
override is accepted. A different value (for example `(DELAY 2)`)
would fail closed with the targeted
`wait-count parameter ... wait counts remain deferred` diagnostic
because per-activation wait-count specialization has not shipped.

## 12. Rule-Triggered Transaction

```lisp
(actor rule_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (output done))
  (transaction worker
    (wait 4)
    (complete done))
  (rule launch fire
    (trigger worker)))
```

Use this when:

- you want an actor-level rule to activate a transaction once per
  pulse on `fire`
- the transaction does not need to be called from another
  transaction body
- you want one rule per trigger source

The rule emits a one-cycle trigger source and the generated handoff
drives the worker's start.

**Walkthrough.** A `(rule NAME GUARD body...)` clause is an
actor-level rule whose body fires when `GUARD` is asserted. Here
`(rule launch fire ...)` triggers whenever the input port `fire`
pulses. The body `(trigger worker)` activates a generated instance
of the `worker` child. Like `spawn`, `trigger` makes `worker` a
generated child so the composition top wires the rule's one-cycle
source signal into the worker's start port. The rule does not
itself wait for `worker.done`; the worker raises the actor-level
`done` output when it completes via `(complete done)`.

## 13. Repeat-Body With Generated Do

```lisp
(actor repeat_do_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input n (width 3))
    (output done))
  (transaction parent
    (on start)
    (repeat n
      (do worker))
    (complete done))
  (transaction worker
    (complete done)))
```

Use this when:

- you want to call a child transaction N times in sequence
- the child's `done` pulse gates the next iteration
- the count is a runtime-known input (`n`) bounded to a known
  width

This pattern uses a local `(do worker)` inside the top-level
repeat. Each iteration starts the worker and waits for its fresh
`done` pulse before the repeat check loops.

**Walkthrough.** `(input n (width 3))` adds a 3-bit input port that
carries the runtime loop count. Inside `parent`, `(repeat n body...)`
lowers to a counter region that loads `n` once on entry and
decrements until zero. The body `(do worker)` is a local blocking
call — `worker` is referenced only inside the repeat body, so the
lowerer keeps it in the parent scheduled module rather than
emitting a separate generated child. Each iteration waits for the
local worker's `done` pulse before the repeat check evaluates and
either loops or falls through to `(complete done)`. The runtime
guard "zero `n` bypasses the body" is provided by the standard
repeat-counter init: if `n` arrives as zero, the schedule skips
straight to the next clause.
