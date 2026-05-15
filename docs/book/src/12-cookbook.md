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
