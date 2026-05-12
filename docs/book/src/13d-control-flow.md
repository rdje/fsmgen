# Control Flow

## `(when condition body...)` — Inline Branching

```lisp
(when mode
  (drive write_path)
  (drive write_done))

(when (> counter 0)
  (drive inc))

(when (== opcode 3)
  (drive error_phase))
```

**Condition**: port name, or any `.fsm` expression.

**Lowering**: `?condition` decision state.
```lisp
(test_tx_when_2
  (?mode
    (=1 (-> write_body_states))    ;; true: execute body
    (=0 (-> next_top_level))))     ;; false: skip body
```

The body tail exits to the same next top-level state, including when the
`when` appears inside a switch branch.

## `(switch signal (value body...)...)` — Multi-Way Dispatch

```lisp
(switch opcode
  (0 (drive read_path))
  (1 (drive write_path))
  (2 (drive error_path))
  (3 (drive idle_path)))
```

Each branch value must be unique. Body clauses are expanded inline, and each
branch tail exits to the first state after the whole switch.

**Lowering**: `?signal` decision tree.
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> read_body_states))
    (=1 (-> write_body_states))
    (=2 (-> error_body_states))
    (=3 (-> idle_path_states))
    (=0 (-> skip))))              ;; default fallthrough
```

## Mixing Control Flow

```lisp
(transaction read_modify_write
  (on start (sample addr as base))

  ;; Read phase
  (drive read_cmd)
  (await done)
  (sample rdata as old_val)

  ;; Conditional modify
  (switch old_val
    (0 (drive set_default))
    (255 (drive clear_flag))
    (other (drive increment)))

  ;; Write back
  (drive write_cmd)
  (await done)
  (complete done))
```

## Nested Control Flow

`(when ...)` and `(switch ...)` can be nested:

```lisp
(switch opcode
  (0 (drive read)
     (when error_flag
       (drive error_phase)))
  (1 (drive write)
     (switch sub_op
       (0 (drive fast_write))
       (1 (drive slow_write)))))
```

## I2C Example with Switch

```lisp
(transaction i2c_transfer
  ...
  (switch is_read
    (1 (repeat 8
         (drive scl 1)
         (shift_left rdata sda_in)
         (drive scl 0)))
    (0 (repeat 8
         (drive scl 1)
         (drive sda data_bit)
         (drive scl 0))))
  ...)
```

Read branch: captures 8 bits via shift register.
Write branch: drives 8 bits of data.
Both branch repeats exit to the same post-switch STOP sequence when their
repeat checks complete.
