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
- `(port value)` — guarded assignment when the condition holds
- `(trigger transaction)` — guarded assertion of the transaction start signal
- `(priority over other_rule)` — parsed metadata, currently not enforced

**Lowering**: Combinational DT block containing guarded flopped assignments.

```lisp
(-always_ready
  (<- (valid 1) <ready)
  (<- (main_transfer_start 1) <ready))
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
  (<- (valid 1) <err)
  (<- (err 1) <err))
```

### Parsed Priority

```lisp
(rule high_pri
  (priority over always_ready)
  (when start)
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
