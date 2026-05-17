# Control Flow

This chapter describes transaction-local control flow. In this context,
`(when condition body...)` always carries a body and lowers to scheduled
conditional states.

Rules use a related but different guard form:

```lisp
(rule always_ready
  (when ready)
  (valid 1))
```

In a rule, `(when condition)` is a guard clause for the rule's actions; it is
not a body-bearing control-flow form. The preferred rule shorthand is:

```lisp
(rule always_ready ready
  (valid 1))
```

See [Rules and Priorities](13g-rules.md) for rule guard lowering.

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

The form is exact: `(when condition body...)`, with a scalar or list-form
condition and at least one list-form body clause before branch expansion.

**Lowering**: `?condition` decision state.
```lisp
(test_tx_when_2
  (?mode
    (=1 (-> write_body_states))    ;; true: execute body
    (=0 (-> next_top_level))))     ;; false: skip body
```

The body tail exits to the same next top-level state, including when the
`when` appears inside a switch branch. Current body support includes drive,
await, sample, complete, nested `when`, repeat bodies, actor-owned bank
`store`/`load`, shipped `wait` clauses, and the shipped data-operation family
(`update`, `set`, shifts, `assemble`, and `extract`).

## `(switch signal (value body...)...)` — Multi-Way Dispatch

```lisp
(switch opcode
  (0 (drive read_path))
  (1 (drive write_path))
  (2 (drive error_path))
  (3 (drive idle_path)))
```

Each explicit branch value must be unique. An optional fallback can be
written as `default` or `_`. Body clauses are expanded inline, and each branch
tail exits to the first state after the whole switch.

The form is exact: `(switch signal (value body...)...)`, with a scalar
non-empty signal and one or more list-form branches. Each branch must carry a
scalar value and at least one list-form body clause before branch expansion.

**Lowering**: `?signal` decision tree.
```lisp
(dispatch_switch_4
  (?opcode
    (=0 (-> read_body_states))
    (=1 (-> write_body_states))
    (=2 (-> error_body_states))
    (=3 (-> idle_path_states))
    (default (-> skip))))         ;; default fallthrough
```

The `default` selector is semantic, not a copied literal. In `.fsm`, a
`default` branch means "none of the explicit sibling branch predicates matched."
For the example above, the default path is equivalent to:

```lisp
(! (| (== opcode 0)
      (== opcode 1)
      (== opcode 2)
      (== opcode 3)))
```

This is deliberately the logical negation of the OR of all explicit branch
predicates, not a repeated `=0` case. If explicit predicates overlap, the
default branch excludes their union. If the explicit values are exhaustive for
the signal width, the default branch is unreachable but remains a valid
fallthrough target in the generated `.fsm`.

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
    (default (drive increment)))

  ;; Write back
  (drive write_cmd)
  (await done)
  (complete done))
```

## Nested Control Flow

The shipped nested-control subset is explicit. A `switch` branch may contain a
`when` body, a `when` body may contain another `when`, and `repeat` bodies are
supported inside top-level `when` and `switch` bodies. The shipped repeat-body
clause surface is named drive calls, `await`, `sample`, `update`, `set`,
`shift_left`, `shift_right`, `assemble`, `extract`, actor-owned bank `store`
and `load`, shipped `wait` clauses, top-level repeat-body local `(do child)`,
top-level repeat-body generated `(do child)` for already generated child
targets, top-level repeat-body generated `(do child (params ...))` with
static parameter overrides, top-level when-body nested repeat local,
generated-child, or static-parameter generated `(do child)`, top-level
switch-branch nested repeat local or generated-child `(do child)`, and
top-level repeat-body spawn with optional static `(params ...)`, optional
`(bind ...)`, and optional declared same-domain
`(domain NAME)` metadata followed by same-body `await_all` or by same-body
`await_any` when exactly one spawn is pending. Samples may appear before or
after repeat-body spawn before that same-body sync; they lower to an explicit
sample state before the later spawn state or before `await_all` /
single-pending `await_any`, matching source order. Samples may also appear
before or after repeat-body `do`; they lower before the do state or after the
do state's fresh done guard and before the repeat check. Multi-pending
repeat-body `await_any` is shipped only when a later same-body `await_all`
drains the same outstanding spawn set before the repeat check; new
repeat-body `spawn` or `do` clauses before that drain remain rejected.
Repeat-body generated `do`
accepts already generated child targets or static `(params ...)` overrides,
optional `(bind ...)` input/output handoffs, and optional same-domain
`(domain NAME)` metadata; those handoffs and domain summaries are
wired/recorded once for the lexical generated do instance. Cross-domain
repeat-body `do` remains deferred. The when-contained nested subset accepts
only a repeat directly inside a top-level `when` body and accepts either local
plain `(do child)`, plain generated-child `(do child)` for targets already
generated elsewhere, or static-parameter generated `(do child (params ...))`;
it rejects bindings and domain metadata. The
switch-contained nested subset accepts the same local or plain generated-child
forms in a repeat directly inside a top-level `switch` branch. Both nested
subsets keep the nested repeat check gated by the child's fresh done pulse,
and both still reject deeper branch nesting and loop-contained repeats.
Broader outstanding-child semantics, generated or spawned nested activation
beyond the documented top-level branch-contained generated do cases, `stage`,
`contract`, nested `while`, and nested `until` forms remain outside the
shipped repeat-body subset.
Unsupported nested forms now fail closed during lowering instead of
disappearing from scheduled `.fsm` output.

```lisp
(switch opcode
  (0 (drive read)
     (when error_flag
       (drive error_phase))))
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
         (drive sda data[7])
         (drive scl 1)
         (drive scl 0)
         (shift_left data 0))))
  ...)
```

Read branch: captures 8 bits via shift register.
Write branch: drives the sampled data byte MSB-first and shifts the sampled
byte left after each bit.
Both branch repeats exit to the same post-switch STOP sequence when their
repeat checks complete.
