# Rules and Priorities

Rules are combinational guard blocks. They fire when their condition is true,
independent of the transaction state machine.

## Rule Syntax

```lisp
(rule always_ready
  (when ready)
  (valid 1)
  (trigger main_transfer))
```

**Actions**:
- `(port value)` — assignment, fires when condition holds
- `(trigger transaction)` — assert transaction's start signal
- `(priority over other_rule)` — inline priority

**Lowering**: Combinational DT block with guarded assignments.

```lisp
(-always_ready
  (= (valid> 1) <ready)
  (= (main_transfer_start 1) <ready))
```

## Rule Examples

### Error Gate

```lisp
(rule error_gate
  (when err)
  (valid 1)
  (err 1))
```

**DT block**:
```lisp
(-error_gate
  (= (valid> 1) <err)
  (= (err> 1) <err))
```

### Priority

```lisp
(rule high_pri
  (priority over always_ready)
  (when start)
  (rdata 0))
```

When both `high_pri` and `always_ready` could fire, `high_pri` wins.

## Priorities

```lisp
;; Separate section
(priority main_transfer over chained)
(priority read_burst over write_burst)
```

Priority is informational for the scheduler. When two rules/transactions
could drive the same output, the higher-priority one wins.

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
