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
- `(trigger transaction)` — guarded one-cycle delayed pulse on the transaction
  start signal
- `(priority over other_rule)` — parsed metadata, currently not enforced

**Lowering**: Non-state DT block containing one guarded action block in the
current scheduler. The shorthand scalar guard and the long-form `(when ...)`
guard both become the public parser `when` field. Scheduled `.fsm` emission
renders that rule guard once around the actions instead of repeating it on
every assignment. Ordinary `(port value)` actions are guarded flopped
assignments; `(trigger transaction)` uses `<1` so the transaction start is a
pulse rather than a sticky request bit.

```lisp
(-always_ready
  (<ready
    (<- (valid 1))
    (<1 (main_transfer_start 1))
  )
)
```

## Trigger Fan-In

Current shipped rule-trigger lowering drives the transaction start signal
directly. If several rules trigger the same transaction, each rule emits a
guarded `<1` assignment to the same `transaction_start` LHS. The downstream
`.fsm` backend consolidates same-LHS enables, so the generated HDL is
OR-equivalent and the transaction starts when any triggering rule fires.

```lisp
(-r0
  (<a
    (<1 (work_start 1))
  )
)

(-r1
  (<b
    (<1 (work_start 1))
  )
)
```

That behavior is sufficient for transaction activation, but it is not
provenance-preserving. When two rules trigger the same transaction in the same
cycle, the scheduled artifact exposes only the final `work_start` pulse; it
does not expose distinct `r0_work` and `r1_work` request sources.

The R14 backlog keeps the more general trigger fan-in form explicit until it
is implemented: each rule/transaction pair should get a distinct one-bit
trigger source, such as `r0_work` and `r1_work`, and a generated combinational
fan-in should drive `work_start` from the OR of those sources without adding a
cycle.

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

Until that backlog item lands, users should treat multiple rule triggers for
the same transaction as OR-equivalent for activation but not inspectable as
separate scheduled `.fsm` trigger sources.

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

Inline priority is accepted by the parser and ignored by current lowering.
It does not resolve conflicting drives yet.

## Priorities

```lisp
;; Separate section
(priority main_transfer over chained)
(priority read_burst over write_burst)
```

Priority declarations are informational in the current scheduler. When two
rules/transactions could drive the same output, priority resolution is still
deferred rather than enforced.

## Resources

```lisp
(resources
  (resource shared_bus (arbiter priority))
  (resource mem_port   (arbiter round_robin)))
```

Resources are shared hardware that only one transaction can use at a time.
Arbiter types: `priority`, `round_robin`.

Resource lowering is deferred — resources are parsed but not yet enforced
by the scheduler.
