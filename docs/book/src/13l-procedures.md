# Reusable Procedures

In IAL1, a **procedure** is a named, parameterized block of clauses you can reuse across
transactions instead of repeating yourself. It is the high-level-language idea of a
*function* — a callable block of code with its own actual arguments. Inline
substitution and handshake expansion have the distinct qualification boundaries
described below.

A procedure can be called **two ways**, and you pick which one at each call site:

- **Inline** — `(call NAME actuals...)` expands the body at the call site (no
  hardware cost, no instance). Best for small reusable snippets.
- **Handshake** — `(call NAME actuals... as INST)` emits a transaction with
  start/done and argument bindings. Its local-controller execution repair
  remains open; see the handshake section before relying on this form.

The same `(proc ...)` definition works for both — the trailing `as INST` is the only
thing that switches conventions.

## Defining a procedure

```text
(proc NAME
  (params PARAMSPEC...)   ;; the call parameters (formals), wrapped in (params ...)
  BODY...)               ;; clauses that may reference the parameters by name
```

A `PARAMSPEC` is one of:

- `(P (width N))` — an **in** (value) parameter: the call passes a value in.
- `(out P (width N))` — an **out** parameter: the call passes a signal the procedure
  writes back into.

A procedure is **not** a transaction: it has no `(on ...)` trigger and is never
scheduled on its own. It exists only to be `(call)`ed. Use `(params)` with no entries
for a procedure that takes no arguments.

## Inline calls — `(call NAME actuals...)`

An inline call **macro-expands** the procedure body at the call site, replacing each
parameter with its actual. There is no runtime cost, no instance, and no handshake —
the emitted `.fsm` is byte-identical to writing the substituted clauses out by hand.

The current conditional-normalization boundary has one tracked exception:
`cond` inside an inline procedure body reaches the scheduler unexpanded and
refuses as `unsupported '(cond ...)' clause in transaction body`. Put the `cond`
at the transaction call site and call an ordinary procedure from its branches
until the repair qualifies. Standalone normalization would newly admit a first
sample-only procedure `cond` as activation rather than an ordinary branch, so
the explicit source-intent prerequisite must qualify before integration.
[Procedure safety qualification](../../../docs/audits/procedure-cond-normalization-20261002/scope.txt)
retains that candidate and the restored current refusal. Other first-operation
conditional shorthand can also select entry activation; use an explicit `(on start)` before it. An
authored sample-only `when` retains its documented entry meaning when inlined.

```lisp
(actor acc_demo
  (interface (input start) (input din (width 8)) (output done) (output total (width 8)))

  (proc accumulate (params (in (width 8)))
    (update total (+ total in)))

  (transaction main
    (on start)
    (sample din as s)
    (call accumulate s)          ;; expands to: (update total (+ total s))
    (call accumulate (+ s 1))    ;; expands to: (update total (+ total (+ s 1)))
    (complete done)))
```

An actual can be a plain signal **or a whole expression** — it is substituted
verbatim (note the second call passes `(+ s 1)`).

Several parameters substitute positionally:

```lisp
(actor madd_demo
  (interface (input start) (input a (width 8)) (input b (width 8))
             (output done) (output total (width 8)))

  (proc madd (params (x (width 8)) (y (width 8)))
    (update total (+ x y)))

  (transaction main
    (on start)
    (sample a as av)
    (sample b as bv)
    (call madd av bv)            ;; expands to: (update total (+ av bv))
    (complete done)))
```

Because an inline call is just expansion, it works **anywhere a clause is allowed** —
including inside `when`, `switch`, `while`, and `until` bodies:

```lisp
(actor loop_proc
  (interface (input start) (input busy) (input din (width 8))
             (output done) (output total (width 8)))

  (proc step (params (v (width 8)))
    (update total (+ total v)))

  (transaction main
    (on start)
    (sample din as s)
    (while busy
      (call step s))             ;; the body of `step` runs each loop iteration
    (complete done)))
```

### Out-parameters (write-back)

An `(out NAME (width N))` parameter names a **caller signal the procedure writes into**
— the caller picks the destination per call, so one procedure can drive different
signals. An out-parameter's actual must be a plain signal (an lvalue), not an
expression. In- and out-parameters mix freely and substitute positionally:

```lisp
(actor outp_demo
  (interface (input start) (input din (width 8)) (output done)
             (output r1 (width 8)) (output r2 (width 8)))

  (proc inc_into (params (in (width 8)) (out r (width 8)))
    (update r (+ in 1)))

  (transaction main
    (on start)
    (sample din as s)
    (call inc_into s r1)          ;; expands to: (update r1 (+ s 1))
    (call inc_into (+ s 1) r2)    ;; expands to: (update r2 (+ (+ s 1) 1))
    (complete done)))
```

## Handshake calls — `(call NAME actuals... as INST)`

The trailing `as INST` expands the procedure into a local transaction: parameters
become input/output ports and its body becomes the transaction body. The emitted
call site contains bindings and `(do)`-style start/done controls. The intended
contract captures arguments, waits for completion and returns outputs; the
controller limitation below prevents treating this expansion as delivered
execution.

```lisp
(actor hs_demo
  (interface (input start) (input din (width 8)) (output done) (output result (width 8)))

  (proc inc_into (params (in (width 8)) (out r (width 8)))
    (update r (+ in 1)))

  (transaction main
    (on start)
    (sample din as s)
    (call inc_into s result as a0)   ;; handshake: pass s -> in, run, read r -> result
    (complete done)))
```

The emitted carrier contains scoped input/output bindings and start/done
handshakes for this expansion. Execution remains subject to the tracked local
transaction-controller repair (SEM `.32.1.3.3.1.3`, decision `0109`): this
example currently has an unreachable sample state and disconnected local
control. Successful lowering and binding text do not establish a working call.
Use the inline convention for qualified substitution; handshake execution
will be documented as delivered after its controller qualification.

## Choosing a convention

| | `(call NAME actuals)` | `(call NAME actuals as INST)` |
|---|---|---|
| Form | inline substitution | port-binding handshake |
| Cost | none (macro-expanded) | a one-shot child block + start/done |
| Hardware | no instance | a synthesized child transaction |
| Latency | folds into the surrounding states | the call blocks until the child's `done` |
| Use when | small reusable snippets | intended for separate hardware; execution repair pending |

Both conventions support in- and out-parameters identically.

## A realistic example — combining procedures with control flow

Procedures compose with the rest of the language. Here an inline procedure does the
per-iteration work of a `while` loop, and a `(exit-when)` leaves the loop early:

```lisp
(actor crc_step_demo
  (interface
    (input start)
    (input busy)
    (input abort)
    (input din (width 8))
    (output done)
    (output acc (width 8)))

  ;; per-byte mixing step, reused each iteration
  (proc mix (params (b (width 8)))
    (update acc (^ acc b)))

  (transaction main
    (on start)
    (while busy
      (sample din as byte)
      (call mix byte)              ;; inline: (update acc (^ acc byte))
      (exit-when abort))           ;; leave the loop early on abort
    (complete done)))
```

## Boundaries (fail-closed)

Hardware has no call stack and no dynamic dispatch, so the following fail closed with
a targeted diagnostic:

- **Recursion** (direct or transitive) — `recursive procedure call ... is not lowerable
  to hardware`.
- **Unknown procedure** name in a `(call ...)`.
- **Argument-count mismatch** between the call and the `(params ...)`.
- An **expression** passed where an **out-parameter** expects a plain signal.
- A handshake `(call ... as)` **missing its instance name**.
- A handshake procedure whose **name collides with an existing transaction**.
- A malformed `(proc ...)` — missing name, missing `(params ...)`, or an empty body.

## Notes and current limits

- Procedures are an **ISF-level** construct: the inline form desugars to ordinary
  clauses, and the handshake form reuses the existing child-activation machinery —
  neither raises the abstraction level (see the
  [Feature Support Matrix](13k-isf-feature-support-matrix.md)).
- In the handshake form the synthesized child is currently a reused sibling block, so
  `INST` is a label — two handshake calls to the same procedure share one hardware
  block (sequential reuse). Giving each call a distinct instance is a future
  refinement.
