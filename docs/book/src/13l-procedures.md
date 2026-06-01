# Reusable Procedures

A **procedure** is a named, parameterized block of clauses you can reuse across
transactions instead of repeating yourself. It is the high-level-language idea of a
*function* — a callable block of code with its own actual arguments — realized in
hardware terms, and it lowers cleanly to `.fsm`.

A procedure can be called **two ways**, and you pick which one at each call site:

- **Inline** — `(call NAME actuals...)` expands the body at the call site (no
  hardware cost, no instance). Best for small reusable snippets.
- **Handshake** — `(call NAME actuals... as INST)` calls the procedure as its own
  one-shot hardware block (start/done + argument ports). Best for a heavier block you
  want to share as real hardware.

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

The **same** procedure can be called as its own one-shot hardware block: the trailing
`as INST` synthesizes the procedure into a child transaction (each parameter becomes a
port — in → input, out → output — and the body becomes the transaction body) and
drives it with the `(do)`-style handshake. The call site binds the in-arguments,
pulses the child's start, blocks on its done, and reads the out-arguments back.

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

This lowers to exactly a function call in hardware: bind `s` into the child's `in`
port, pulse `inc_into_start`, run `r = in + 1` in the child, assert `inc_into_done`,
read the child's `r` port back into `result`, and continue.

## Choosing a convention

| | `(call NAME actuals)` | `(call NAME actuals as INST)` |
|---|---|---|
| Form | inline substitution | port-binding handshake |
| Cost | none (macro-expanded) | a one-shot child block + start/done |
| Hardware | no instance | a synthesized child transaction |
| Latency | folds into the surrounding states | the call blocks until the child's `done` |
| Use when | small reusable snippets | a heavier block you want shared/instanced |

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
