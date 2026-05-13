# Rules and Priorities

Rules lower to non-state DT guard blocks. Their assignments are guarded by the
rule condition and are independent of the transaction state machine.

## Rule Syntax

```lisp
(rule always_ready ready
  (valid 1)
  (trigger main_transfer))
```

The long form remains accepted and normalizes to the same parser output:

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

This rule-local `(when ready)` is a guard clause, not transaction control flow.
It has no body of its own; it guards the rule actions that follow it. The
body-bearing `(when condition body...)` form is only described in
[Control Flow](13d-control-flow.md) because it is a transaction clause.

**Actions**:
- `(port value)` — guarded assignment when the condition holds
- `(trigger transaction)` — guarded one-cycle delayed pulse on a per-rule
  trigger source; generated fan-in drives the transaction start signal
- `(priority over other_rule)` — structurally validated metadata, currently
  not enforced

Rule actions are structurally validated before the actor shell is returned.
The current `(port value)` action accepts scalar values only; expression-valued
rule assignments are deferred until the rule lowerer has a real expression
path.

**Lowering**: Non-state DT block containing one guarded action block in the
current scheduler. The shorthand scalar guard and the long-form `(when ...)`
guard both become the public parser `when` field. Scheduled `.fsm` emission
renders that rule guard once around the actions instead of repeating it on
every assignment. Ordinary `(port value)` actions are guarded flopped
assignments. `(trigger transaction)` uses `<1` on a generated
`rule_transaction` source so the request remains pulse-shaped, and a generated
combinational fan-in DT drives `transaction_start` without adding another
cycle.

```lisp
(-always_ready
  (<ready
    (<- (valid 1))
    (<1 (always_ready_main_transfer 1))
  )
)

(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

## Trigger Fan-In

Shipped rule-trigger lowering preserves trigger provenance before transaction
activation. If rule `Rj` triggers transaction `Tk`, the rule DT emits a `<1`
pulse on the generated one-bit source `Rj_Tk`. For each triggered transaction,
the scheduler emits one combinational `Tk_trigger_fanin` DT that drives
`Tk_start` from the OR of all rule sources for `Tk`.

The fan-in is combinational on purpose. It does not add a cycle after the
per-rule `<1` pulse appears; it only separates "which rule requested the
transaction" from "the transaction sees at least one request."

```lisp
(-r0
  (<a
    (<1 (r0_work 1))
  )
)

(-r1
  (<b
    (<1 (r1_work 1))
  )
)

(-work_trigger_fanin
  (= (work_start (| r0_work r1_work)))
)
```

With a single rule source, the generated fan-in assigns the source directly:

```lisp
(-main_transfer_trigger_fanin
  (= (main_transfer_start always_ready_main_transfer))
)
```

## Rule Examples

### Error Gate

```lisp
(rule error_gate err
  (valid 1)
  (err 1))
```

**DT block**:
```lisp
(-error_gate
  (<err
    (<- (valid 1))
    (<- (err 1))
  )
)
```

### Parsed Priority

```lisp
(rule high_pri start
  (priority over always_ready)
  (rdata 0))
```

Inline priority is accepted and structurally validated by the parser, then
ignored by current lowering. It does not resolve conflicting drives yet.

## Priorities

```lisp
;; Separate section
(priority main_transfer over chained)
(priority read_burst over write_burst)
```

Priority declarations are structurally validated as
`(priority lhs over rhs)` and remain informational in the current scheduler.
When two rules/transactions could drive the same output, priority resolution is
still deferred rather than enforced.

## Resources

```lisp
(resources
  (resource shared_bus (arbiter priority))
  (resource mem_port   (arbiter round_robin)))
```

Resources are shared hardware that only one transaction can use at a time.
Arbiter types: `priority`, `round_robin`.

Resource metadata is structurally validated by the parser, including supported
arbiter names and duplicate resource rejection. Resource lowering is still
deferred — resources are not yet enforced by the scheduler.
