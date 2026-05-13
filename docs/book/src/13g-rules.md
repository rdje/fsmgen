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
