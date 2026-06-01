# Local Variables

ISF lets a transaction keep **named local state** and **named intermediate values** —
the *variables* half of programming in ISF (the *functions* half is
[Reusable Procedures](13l-procedures.md)). Both lower cleanly to `.fsm`: a `(local …)`
is a declared register, and a `(let …)` is pure substitution.

## `(local NAME (width N))` — a declared internal register

`(local NAME (width N))` declares an internal register `NAME` of an explicit width,
private to the transaction and not exposed on the interface. The body reads and writes
it like any signal.

A plain `(set tmp expr)` to an undeclared name already works, but its width is only
*inferred*. A `(local …)` **pins the width** — `NAME` is emitted in the module's
`+size` block at the width you choose — which matters for accumulators and temporaries
that must be wider than the values flowing through them.

```lisp
(actor accumulator
  (interface (input start) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (local acc (width 8))      ;; an explicit 8-bit internal register
    (sample din as s)
    (set acc (+ acc s))        ;; read + write the local like any signal
    (update result acc)
    (complete done)))
```

### `(default V)` / `(init V)` — an initial value

An optional `(default V)` gives the local an initial value; **`(init V)` is an accepted
synonym**. A transaction-local is re-initialized **each time the transaction runs**
(like a software local variable), so the value is materialized as a set-to-`V` on entry.
`V` is a non-negative integer literal that must fit in the declared width:

```lisp
(transaction main
  (on start)
  (local acc (width 8) (default 0))   ;; starts at 0 every run
  (sample din as s)
  (set acc (+ acc s))
  (update result acc)
  (complete done))
```

> **`(default …)` is init-on-entry, not a hardware reset value.** It runs each time the
> transaction starts. The value a register holds out of *hardware reset* (e.g. for
> register maps) is a separate, deeper feature — when no reset value is specified a
> register resets to all-0s.

A `(local …)` fails closed if its name collides with an interface port, if the
`(width N)` is missing or not a positive integer, or if a `(default V)` / `(init V)` is
not a non-negative integer that fits in the width.

## `(let NAME EXPR)` — named intermediate values

Where `(local …)` is a register, `(let NAME EXPR)` simply **names an expression**:
`NAME` is substituted by `EXPR` in the rest of the body. It is a pure desugar — no
register, no extra cycle — useful for naming a sub-expression used in several places.

```lisp
(actor let_demo
  (interface (input start) (input a (width 8)) (input b (width 8))
             (output done) (output result (width 8)))
  (transaction main
    (on start)
    (sample a as av)
    (sample b as bv)
    (let sum (+ av bv))          ;; name the sub-expression
    (update result (+ sum 1))    ;; lowers as: (update result (+ (+ av bv) 1))
    (complete done)))
```

A `(let)` is scoped to the rest of its enclosing body; a `(let)` inside a `when` /
`switch` / `while` / `until` body may shadow an outer one. It fails closed on redefining
an already-bound name or on a name that collides with an interface port.

## `(local)` vs `(let)`

| | `(local NAME (width N))` | `(let NAME EXPR)` |
|---|---|---|
| What it is | a declared register (state) | a name for an expression (no state) |
| Cost | one register | none (substituted away) |
| Lifetime | holds a value across the transaction's states | just shorthand at each use |
| Use when | you need to accumulate / update state | you want to name a repeated sub-expression |

## A worked example — combining locals, procedures, and control flow

```lisp
(actor running_max
  (interface (input start) (input busy) (input din (width 8)) (output done) (output peak (width 8)))

  ;; a reusable comparison-and-keep step over the internal running peak
  (proc keep_max (params (v (width 8)))
    (when (> v cur_peak)
      (set cur_peak v)))

  (transaction main
    (on start)
    (local cur_peak (width 8) (default 0))   ;; reset the running peak each run
    (while busy
      (sample din as s)
      (let bumped (+ s 1))                    ;; name an intermediate
      (call keep_max bumped))                 ;; inline the reusable step
    (update peak cur_peak)                     ;; publish the result to the output
    (complete done)))
```

This reads like a small program — a declared local with an initial value, a named
intermediate, a reusable procedure, and a loop — and lowers to a single scheduled
`.fsm` with no runtime overhead beyond the register and the states the work needs.
