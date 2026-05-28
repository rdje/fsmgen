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
