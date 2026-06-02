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

## `(cond (condition body...)... (else body...))` — If / Else-If / Else

`(cond ...)` is the **priority** conditional chain. It tests each branch's condition in
order; the **first** branch whose condition holds runs (and only it), and the optional
final `(else ...)` runs when none held. Where `(switch ...)` dispatches on one signal's
*value*, `(cond ...)` chooses among independent boolean conditions (signals or expressions)
— the if / else-if / else of a high-level language, without hand-nesting `when`.

```lisp
(cond
  ((== mode 0) (drive read))
  ((== mode 1) (drive write))
  ((== mode 2) (drive erase))
  (else        (drive nop)))
```

`(cond ...)` is pure ISF sugar: the parser desugars it into a `when`-chain with
**accumulated negated guards**, so a later branch fires only when every earlier condition
was false:

```lisp
(when (== mode 0) (drive read))
(when (& (! (== mode 0)) (== mode 1)) (drive write))
(when (& (! (== mode 0)) (! (== mode 1)) (== mode 2)) (drive erase))
(when (& (! (== mode 0)) (! (== mode 1)) (! (== mode 2))) (drive nop))   ;; else
```

The branch conditions are evaluated across the chain (each `when` is a decision), so they
should be **stable** while the chain runs — sample a volatile input first (as you would for
`when`/`switch`). The `(else ...)` branch must be **last** (if present); a branch must have a
condition (or be `else`) and a non-empty body, or the form **fails closed**. A `(cond ...)`
nests anywhere a `when` may appear, including inside another `(cond ...)` branch.

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

## `(exit-when condition)` — Mid-Loop Early Exit

`(exit-when condition)` leaves the enclosing `while`/`until` loop the cycle
`condition` holds, instead of waiting for the loop's own top/bottom condition test.
It is accepted **directly inside a `while` body or an `until` body** and lowers to a
single decision state: when `condition` is true the loop's exit edge is taken
(the same state the loop's own condition exits to); otherwise control falls through
to the next body clause and the loop continues normally.

```lisp
(actor early_exit
  (interface
    (input start)
    (input busy)
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8)))
  (transaction main
    (on start)
    (while busy
      (update result din)
      (exit-when go)        ;; leave the loop the cycle `go` is high
      (update result din))
    (complete done)))
```

This lowers the `(exit-when go)` clause to `(?go (=1 (-> <loop exit>)) (=0 (-> <next
clause>)))`. The exit edge reuses the loop's computed exit target, so an early exit
behaves exactly like a normal loop exit (the watchdog counts the cycles actually
spent in the loop).

`(exit-when ...)` may also appear inside a `when` body that is itself nested in the
loop — its true edge still leaves the **whole** loop (not just the `when`):

```lisp
(while busy
  (when error
    (exit-when fatal))   ;; on a fatal error, leave the loop entirely
  (drive step))
```

`(exit-when ...)` that is not inside a `while`/`until` loop fails closed: at the
transaction top level or in a `repeat` body the clause allow-list rejects it
(`unsupported '(exit-when ...)' clause in <context>`); in a `when` that is not nested
in a loop it fails closed with `'(exit-when ...)' is only valid inside a 'while'/'until'
loop body`.

## `(continue-when condition)` — Skip To Next Iteration

`(continue-when condition)` is the loop *continue* primitive — the companion to
`(exit-when)`. The cycle `condition` holds it **skips the rest of the current
iteration** and jumps to the loop's tail condition check, which re-evaluates the loop
condition and either runs another iteration or exits; otherwise control falls through
to the next body clause.

```lisp
(while busy
  (sample din as s)
  (continue-when (== s 0))   ;; skip zero bytes; re-check `busy` and loop again
  (drive process))
```

This lowers `(continue-when (== s 0))` to `(?(== s 0) (=1 (-> <loop check>)) (=0 (->
<next clause>)))`, where `<loop check>` is the loop's tail decision (the `while`/`until`
back-edge check). Like `(exit-when)`, it is accepted directly in a `while`/`until` body
**and inside a `when` nested in one** (where it still targets the whole loop's check),
and fails closed elsewhere (with a diagnostic naming `continue-when`). Together
`(exit-when)` and `(continue-when)` are the *break* / *continue* pair of a high-level
loop.

## `(for (i N) body...)` — Indexed Counted Loop

`(for (i N) body...)` runs `body` exactly `N` times while exposing a **loop index** `i`
that counts `0, 1, … N-1` to the body — the ergonomic indexed loop a high-level language
has. A bare `(repeat N body)` runs `body` N times but gives the body no index; `(for ...)`
adds one, so the body can do indexed work (per-iteration values, addressing).

```lisp
(transaction sum_first_four
  (on start)
  (for (i 4)
    (update total (+ total i)))   ;; i = 0,1,2,3 across the four iterations -> total += 0+1+2+3
  (complete done))
```

`(for ...)` is pure ISF (IAL1) sugar: the parser desugars it — before procedure and
`let` expansion — into a declared index local plus a counted `(repeat ...)` with a tail
increment, both of which already lower:

```lisp
(local i (width W) (default 0))      ;; W = bits to hold N; i starts at 0
(repeat N
  body...
  (set i (+ i 1)))                    ;; i advances 0 -> 1 -> … at the end of each iteration
```

Because the index advances at the *tail* of each iteration, the body reads `i` as
`0` on the first pass, `1` on the second, … `N-1` on the last — a 0-based index. The
counted `(repeat ...)` it lowers to runs the body exactly `N` times and then completes
(see [the counted-repeat schedule](13b-transactions.md)).

To loop a **variable** number of times, give the index an explicit width so the count may
be a parameter, constant, or runtime signal:

```lisp
(for (i (width 8) n)            ;; n is a parameter/constant/runtime scalar
  (update total (+ total i)))   ;; runs n times; i = 0 … n-1 (n == 0 runs zero times)
```

`(for (i (width W) COUNT) ...)` declares the index at width `W` (a positive integer
literal — you size it to hold `COUNT-1`) and accepts any count the counted `(repeat ...)`
accepts (literal, actor/transaction parameter, package/actor constant, or known-width
runtime scalar). The plain `(for (i N) ...)` form requires a **literal** `N >= 1` (its
width auto-sizes); use the explicit-width form for a non-literal count.

To iterate over a **range** that does not start at zero, use the `from … to …` form:

```lisp
(for (i from 2 to 5)            ;; i = 2, 3, 4 (the upper bound is exclusive)
  (update total (+ total i)))
```

`(for (i from A to B) ...)` counts `i = A, A+1, … B-1` — `B-A` iterations starting at `A`,
with the upper bound `B` exclusive. `A` and `B` are literal non-negative integers with
`B > A` (an upward, non-empty range); the index width auto-sizes to hold `B`. It desugars
to `(local i (width W) (default A))` plus `(repeat (B-A) body... (set i (+ i 1)))`.

A trailing `step S` strides the index by `S` (default `1`) — useful for strided access:

```lisp
(for (i from 0 to 10 step 2)    ;; i = 0, 2, 4, 6, 8 (each value < 10)
  (update total (+ total i)))
```

`(for (i from A to B step S) ...)` runs `ceil((B-A)/S)` iterations counting
`i = A, A+S, A+2S, …` (each value `< B`), with `S` a positive integer literal; it desugars
with `(set i (+ i S))` as the tail increment and sizes the width to hold the
post-final-increment value.

A `(for ...)` may be a **top-level transaction clause** or **directly nested inside
another `(for ...)` body** — nested loops with independent indices:

```lisp
(for (i 3)
  (for (j 2)
    (update grid (+ grid (+ i j)))))   ;; body runs 3 * 2 = 6 times; i = 0..2, j = 0..1
```

Both index `(local …)` declarations are hoisted to the transaction top, the inner index
resets to its start value at the head of each outer iteration, and the loops lower to a
nested counted `(repeat …)` (each with its own counter — see *Nested Counted Loops*). The
nesting can go arbitrarily deep.

A `(for ...)` may also be **embedded in a control-flow body** — inside a
`when`/`switch`/`while`/`until`/`repeat` body. Its index `(local …)` is hoisted to the
transaction top and an index reset is prepended in the body, so the loop restarts each time
its enclosing body is (re-)entered:

```lisp
(while busy
  (for (i 4)                       ;; each while iteration runs the inner loop afresh (i = 0..3)
    (update checksum (^ checksum i))))
```

A zero width, a literal-zero count, an implicit-width non-literal count, a non-upward range
(`B <= A`), non-literal range bounds, and an empty body all **fail closed** with a clear
diagnostic:

```lisp
;; rejected: count must be >= 1
(for (i 0) (update total (+ total i)))
```

## Nested Counted Loops

A counted `(repeat …)` may sit **inside** another `(repeat …)` body, so the body runs
`outer × inner` times:

```lisp
(repeat 3
  (repeat 2
    (update count (+ count 1))))   ;; runs 3 * 2 = 6 times
```

Each repeat instance gets its own counter — the outermost keeps `<tx>_cnt`, a nested
repeat uses a unique `<tx>_cnt_<n>` — so the inner and outer countdowns never collide, and
the nesting can go arbitrarily deep. Lowering is check-first throughout: the outer check's
continue edge enters the inner loop, and the inner check's exit edge returns to the outer
check. (A nested indexed `(for …)` desugars onto exactly this nested-`(repeat …)` substrate
— see the *Indexed Counted Loop* section.)

## Where Child Activations Are Allowed

All four child-activation clauses — `(do ...)`, `(spawn ...)`, `(await_all ...)`,
and `(await_any ...)` — are accepted as **top-level transaction clauses**, **inside
a `repeat` body**, and **directly inside a `when` body, a `switch` branch, a
`while` body, and an `until` body**. Inside a branch/loop body they describe a
*conditional* (or loop-conditional) activation: the activation only happens when
the enclosing branch is taken / on each loop iteration.

A **local `(do child)`** — plain or with `(bind ...)` port bindings, no
`(params ...)` overrides, target not generated elsewhere — is the simplest form, a
conditional one-shot activation:

```lisp
(actor conditional_activation
  (interface
    (input start)
    (input cond)
    (input go)
    (input din (width 8))
    (output done)
    (output result (width 8))
    (output worker_done))
  (transaction parent
    (on start)
    (when cond
      (do worker))          ;; accepted: conditional one-shot activation
    (complete done))
  (transaction worker
    (on go)
    (update result din)
    (complete worker_done)))
```

The enclosing branch/loop guards the do-state; when it is entered, the do-state
asserts the child's start handshake (driving any `(bind (input ...))` ports) and
blocks on its done handshake, exactly like a top-level `(do child)`.

A **generated** conditional activation — a `(do child (params ...))` parameter
override — is also supported **directly inside all four branch/loop bodies**
(`when`, `switch` branch, `while`, and `until`). It elaborates a generated child
instance (named `<owner>_<child>_cond_do_<n>`), instantiated and wired in the
generated composition top, exactly like a top-level generated `(do)` (and sharing
the same generated-child composition behavior):

```text
(when c     (do w (params (W 8))))        ;; generated when-body do
(switch sel (0 (do w (params (W 8)))))    ;; generated switch-branch do
(while c    (do w (params (W 8))))        ;; generated while-body do
(until c    (do w (params (W 8))))        ;; generated until-body do
```

A **non-blocking `(spawn child as inst)`** plus an `(await_all ...)` / `(await_any
...)` drain is also accepted in a branch/loop body — a *conditional fan-out + join*.
The spawns assert each child's start handshake without blocking; the drain then
blocks on the accumulated child done handshakes (`await_all` = all, `await_any` =
any). The done-port accumulator is body-local, so the drain belongs in the same
branch/loop body as the spawns it joins:

```lisp
(actor conditional_fan_out
  (interface
    (input start)
    (input cond)
    (input go)
    (input din (width 8))
    (output done)
    (output r1 (width 8))
    (output r2 (width 8))
    (output w1done)
    (output w2done))
  (transaction parent
    (on start)
    (when cond
      (spawn worker1 as w1)   ;; conditional fan-out: start both children…
      (spawn worker2 as w2)
      (await_all done))       ;; …then join on both done handshakes
    (complete done))
  (transaction worker1
    (on go)
    (update r1 din)
    (complete w1done))
  (transaction worker2
    (on go)
    (update r2 din)
    (complete w2done)))
```

The spawned children are instantiated and wired in the composition top exactly like
a top-level spawn fan-out (and share the same multi-instance composition behavior).
Child activation is therefore fully orthogonal across the clause contexts: a `(do)`
(local or generated) and a `(spawn ...)` + drain lower the same way at top level,
in a `repeat`, and in any branch/loop body — a `(do)` is a blocking activation and
a `(spawn ...)`/`(await ...)` pair is a non-blocking fan-out/join, and both kinds of
construct are allowed in those bodies.

The full same-domain support matrix (✓ = lowers; the spawn column means
`(spawn ...)` together with its `(await_all ...)` / `(await_any ...)` drain):

| Context | local `(do)` | generated `(do (params ...))` | `(spawn)` + drains |
| --- | :---: | :---: | :---: |
| top-level transaction | ✓ | ✓ | ✓ |
| `repeat` body | ✓ | ✓ | ✓ |
| `when` body | ✓ | ✓ | ✓ |
| `switch` branch | ✓ | ✓ | ✓ |
| `while` body | ✓ | ✓ | ✓ |
| `until` body | ✓ | ✓ | ✓ |

Across clock domains the staging is narrower than the same-domain surface above, but
it now tracks it for the top-level contexts. A cross-domain `(do child)` through a
`(crossings (activation ...))` is supported at the transaction top level and directly
inside any **top-level body** — a `(repeat ...)` body or a `when`/`switch`/`while`/
`until` branch body (the dual-CDC handshake runs when the branch is taken and re-runs
each iteration inside a repeat/loop; see
[Activation Crossing](13a-actor-interface.md#activation-crossing)). Only a
*deeper-nested* cross-domain `(do)` — one whose container is itself nested inside
another body rather than a direct transaction-body clause — still fails closed with a
"deeper nested cross-domain activation remains deferred" diagnostic.

## Nested Control Flow

The shipped nested-control subset is explicit.

A `switch` branch may contain a `when` body, a `when` body may contain
another `when`, and `repeat` bodies are supported inside top-level `when` and
`switch` bodies.

The shipped repeat-body clause surface is named drive calls, `await`,
`sample`, `update`, `set`, `shift_left`, `shift_right`, `assemble`,
`extract`, actor-owned bank `store` and `load`, shipped `wait` clauses,
top-level repeat-body local `(do child)`, top-level repeat-body generated
`(do child)` for already generated child targets, top-level repeat-body
generated `(do child (params ...))` with static parameter overrides,
top-level when-body nested repeat local, generated-child `(do child)`,
static-parameter generated `(do child (params ...))`, or static-parameter
generated bound `(do child (params ...)

(bind ...))`, top-level switch-branch nested repeat local, generated-child
`(do child)`, or static-parameter generated `(do child (params ...))` with
optional `(bind ...)` handoffs, and top-level repeat-body spawn with optional
static `(params ...)`, optional `(bind ...)`, and optional declared
same-domain `(domain NAME)` metadata followed by same-body `await_all` or by
same-body `await_any` when exactly one spawn is pending.

Samples may appear before or after repeat-body spawn before that same-body
sync; they lower to an explicit sample state before the later spawn state or
before `await_all` / single-pending `await_any`, matching source order.

Samples may also appear before or after repeat-body `do`; they lower before
the do state or after the do state's fresh done guard and before the repeat
check.

Multi-pending repeat-body `await_any` is shipped only when a later same-body
`await_all` drains the same outstanding spawn set before the repeat check;
new repeat-body `spawn` or `do` clauses before that drain remain rejected.

Repeat-body generated `do` accepts already generated child targets or static
`(params ...)` overrides, optional `(bind ...)` input/output handoffs, and
optional same-domain `(domain NAME)` metadata; those handoffs and domain
summaries are wired/recorded once for the lexical generated do instance.

Cross-domain repeat-body `do` remains deferred.

The when-contained nested subset accepts only a repeat directly inside a
top-level `when` body and accepts either local plain `(do child)`, plain
generated-child `(do child)` for targets already generated elsewhere,
static-parameter generated `(do child (params ...))`, or static-parameter
generated bound `(do child (params ...)

(bind ...))`; it may also carry declared same-domain `(domain NAME)` metadata
when static params are present and requires static params whenever bindings
or domain metadata are present.

The switch-contained nested subset accepts the same local, plain
generated-child, static-parameter generated, or static-parameter generated
bound forms in a repeat directly inside a top-level `switch` branch, and it
may also carry declared same-domain `(domain NAME)` metadata when static
params are present.

Both nested subsets keep the nested repeat check gated by the child's fresh
done pulse. A repeat directly inside a top-level `when` body may also contain
one or more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites
when the same nested body reaches `(await_all done)` before the nested repeat
check can loop. A repeat directly inside a top-level `switch` branch may
contain the same multiple generated-spawn plus same-body `await_all` subset.

Both branch-contained paths may use single-pending `(await_any done)`
directly when exactly one generated child is pending.

Both branch-contained paths may also use multi-pending `(await_any done)` as
an observation point only when a later same-body `(await_all done)` drains
the same outstanding generated children before the nested repeat check can
loop.

Those branch-contained nested spawns reuse the static generated-child handoff
model and preserve source-order samples before the spawn or sync states.

### Loop-contained repeat-body local `do`

A plain local `(do child)` — a `(do ...)` with no `(params ...)`, `(bind ...)`,
or `(domain ...)` and a target that is not a generated child — directly inside
a `(repeat ...)` that sits in a single `(while ...)` or `(until ...)` body
lowers cleanly:

```lisp
(actor loop_contained_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker)))
    (complete done))
  (transaction worker
    (complete done)))
```

The scheduled `.fsm` reuses the proven repeat structure inside the loop body:
the loop entry tests `cond`, `repeat_init` re-seeds the repeat counter from
`loops` on each loop iteration, the blocking-do state asserts `worker_start`
and awaits `worker_done`, and `repeat_check` decrements the counter and either
re-runs the repeat block or returns to the loop check. So
`(while cond (repeat N (do worker)))` means "while `cond`, run the worker
`N` times per loop iteration"; `(until ...)` applies the post-test form of the
same shape.

This subset is intentionally narrow. The repeat must sit **directly** in a
single loop body — a repeat reached through an extra `(when ...)`/`(switch ...)`
ancestor, or through more than one loop, stays deferred (see below).

### Loop-contained repeat-body generated `do`

A same-domain **generated** `do` — one carrying static `(params ...)` (and
`(bind ...)`/`(domain NAME)` when static params are present), or targeting a
generated child — also lowers inside a single `(while ...)`/`(until ...)`
-contained repeat:

```lisp
(actor loop_contained_repeat_generated_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (do worker (params (W 8)))))
    (complete done))
  (transaction worker
    (params (W 4))
    (complete done)))
```

One generated child instance is created per lexical `do` site (named
`<tn>_<child>_repeat_do_<ord>`) and re-triggered on each loop iteration — the
blocking-do state asserts the instance `_start` and awaits its `_done`, exactly
like a top-level repeat-body generated `do`. The `_top` composition
instantiates the child with the resolved parameter overrides.

### Loop-contained / deeper-nested repeat-body `spawn` (+ same-body drain)

The basic `(spawn child as inst)` + same-body `(await_all done)` (or
single-pending `(await_any done)`) subset lowers inside a loop-contained or
deeper-nested repeat:

```lisp
(actor loop_contained_repeat_spawn
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (await_all done)))     ;; drains w0 before repeat_check / loop re-entry
    (complete done))
  (transaction worker
    (complete done)))
```

The lowered schedule mirrors the proven top-level repeat-body spawn: the spawn
asserts the instance `_start`, the same-body `await_all` drains the instance
`_done` before `repeat_check` loops (and before the outer loop re-enters at
`repeat_init`), and the child is instantiated in the `_top` composition. (Like
the top-level repeat-body spawn, this is a lowering + composition-planning
subset; the full-HDL `--check-json` path has a pre-existing composition-wiring
limitation that applies equally to the top-level case — see
`docs/COMPOSITION_SCOPE.md`.)

An **undrained** spawn (no same-body `await_all`/single-pending `await_any`
before the repeat check) stays deferred: `Transaction 'parent': loop-contained
repeat-body spawn requires same-body '(await_all done)' or single-pending
'(await_any done)' before the repeat check can loop` (and the `deeper-nested
...` form). A **multi-pending** `(await_any done)` (two or more outstanding
children observed by an `await_any`) is supported as an observation point when
a later same-body `(await_all done)` drains the outstanding children before the
repeat check — for example `(spawn a)(spawn b)(await_any done)(await_all done)`
— matching the top-level / when-body / switch-branch behavior; without the
later `(await_all done)` the outstanding children trip the drain requirement
above. A **cross-domain** generated `do` stays deferred (`cross-domain repeat-body do
remains deferred`); bindings or domain metadata without static `(params ...)`
emit `repeat-body generated do bindings require static '(params ...)'
overrides`. A repeat wrapped by both a loop and a branch (for example
`(while c1 (when c2 (repeat ...)))`) still routes through
`Transaction 'parent': loop-contained repeat-body do remains deferred`.

The multi-pending observation + later-drain shape lowers like this:

```lisp
(actor loop_contained_repeat_multi_await_any
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (while cond
      (repeat loops
        (spawn worker as w0)
        (spawn worker as w1)
        (await_any done)       ;; observe the first child to finish
        (await_all done)))     ;; drain both before repeat_check / loop re-entry
    (complete done))
  (transaction worker
    (complete done)))
```

### Deeper-nested repeat-body local `do`

A plain local `(do child)` inside a `(repeat ...)` reached through more than one
branch ancestor — two or more `(when ...)` clauses (`when⁺ → repeat`), or a
`(when ...)` inside a `(switch ...)` case (`switch → when⁺ → repeat`) — also
lowers:

```lisp
(actor deeper_nested_repeat_do
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input cond1) (input cond2) (input loops (width 3))
    (output done))
  (transaction parent
    (on start)
    (when cond1
      (when cond2
        (repeat loops
          (do worker))))
    (complete done))
  (transaction worker
    (complete done)))
```

Each branch guard reaches the repeat block, which reuses the proven
`repeat_init` → blocking-do → `repeat_check` schedule. (A nested `(switch ...)`
inside a `(when ...)` body or another `(switch ...)` branch is itself an
unsupported clause, so the reachable deeper-nested shapes are exactly these.)

A same-domain **generated** `do` (static `(params ...)`, with `(bind ...)`/
`(domain NAME)` when params are present) also lowers at deeper branch nesting
and instantiates its child in the `_top` composition, exactly like the
loop-contained and top-level generated-`do` cases. The basic `spawn` +
same-body `(await_all done)` (or single-pending `(await_any done)`) subset
likewise lowers at deeper branch nesting (see the loop-contained spawn section
above). A deeper-nested **cross-domain** generated `do` stays deferred and emits
`cross-domain repeat-body do remains deferred`; an **undrained** deeper-nested
`spawn` emits `Transaction 'parent': deeper-nested repeat-body spawn requires
same-body '(await_all done)' or single-pending '(await_any done)' before the
repeat check can loop`. A multi-pending `(await_any done)` followed by a later
same-body `(await_all done)` drain is supported at deeper nesting (as at
top-level / when-body / switch-branch); without the drain it trips the
deeper-nested spawn drain requirement. The generic "supported only for
top-level repeat clauses..." message remains as a safety-net fallback for
shapes not yet classified.

The branch-contained shipped subsets accept one multi-pending
`(await_any done)` observation that the same body's later
`(await_all done)` drains. They reject a **second** post-spawn
`(await_any done)` observation between the first observation and
the drain. The rejected shape adds a second observation after the
later spawn:

```text
(transaction parent
  (on start)
  (when cond
    (repeat n
      (spawn worker as w0)
      (await_any done)           ;; <-- prior observation; accepted
      (do helper)
      (spawn worker as w1)
      (await_any done)           ;; <-- second observation; fail closed
      (await_all done))))        ;; (drain still arrives later)
```

The validator emits `Transaction 'parent': when-body nested repeat
spawn after local do while generated spawns are pending requires
same-body '(await_all done)' drain; '(await_any done)' after the
later spawn remains deferred`. The diagnostic phrase varies by the
intervening do kind (`local do`, `generated-child do`, `generated
do with static params`, `generated do with static params and
bindings`, `generated do with static params and same-domain
metadata`) and by the outer branch (`when-body` vs
`switch-branch`), but the rejection rule is uniform. The deferred
lane is the second observation after the later spawn; until it
ships, authors must end the pending-spawn interval with the
same-body drain (no intervening second observation).

`do` while a nested spawn is pending is shipped for a local plain `(do
child)` in a repeat directly inside a top-level `when` body or a top-level
`switch` branch, and for a plain generated-child `(do child)` in either
top-level branch-contained repeat when the target child is already emitted as
a generated child by another activation site.

The top-level `when` and `switch` local-do pending-spawn forms may also
follow a prior multi-pending `await_any` observation. The matching plain
generated-child pending-spawn forms may also follow a prior multi-pending
`await_any` observation when the generated do instance completes before the
later generated spawn.

Every pending-spawn `do` form requires a later same-body `await_all` drain
before the nested repeat check can loop.

The local do waits for the local child's fresh done pulse; the
generated-child do waits for its deterministic generated do instance's fresh
done handoff.

Neither form clears the generated-spawn done set before the later drain.

Top-level `when` body and top-level `switch` branch nested repeats may also
run static-parameter generated `(do child (params ...))` while generated
nested spawns are pending; that generated do preserves static generated-top
parameter binding, waits for its deterministic generated do instance's fresh
done handoff, and leaves the generated-spawn done set live for the later
drain.

Top-level `when` body and top-level `switch` branch nested repeats may also
run static-parameter generated `(do child (params ...)

(bind ...))` while generated nested spawns are pending; that generated do
wires generated-top input/output binding handoffs once and leaves the
generated-spawn done set live for the later drain.

A top-level `when` body or top-level `switch` branch nested repeat may also
run static-parameter same-domain generated `(do child (params ...) [(bind
...)] (domain NAME))` in that interval; the domain annotation is metadata for
the generated do instance and does not imply CDC.

Static-parameter generated `do`, bound generated `do`, and same-domain
generated `do` after prior multi-pending `await_any` may start a later
generated spawn, run a second post-spawn `await_any`, and then advance to
the mandatory same-body `await_all` drain. Same-domain generated-do
prior-observation forms preserve declared ownership metadata on the
generated do instance across both observations.

Broader outstanding-child semantics, generated or spawned nested activation
beyond the documented top-level branch-contained generated do cases and
branch-contained spawned cases, `stage`, `contract`, nested `while`, and
nested `until` forms remain outside the
shipped repeat-body subset.

Unsupported nested forms now fail closed during lowering instead of
disappearing from scheduled `.fsm` output.

```lisp
(switch opcode
  (0 (drive read)
     (when error_flag
       (drive error_phase))))
```

## `(assert COND [message])` — Verification Invariant

```lisp
(assert (< level depth))
(assert (>= grant request) "grant must cover the request")
```

Capture a design-intent **invariant** — a condition that must hold every cycle —
and project it to a verification-only SystemVerilog assertion. `(assert …)` is a
transaction-level clause; `COND` is any boolean expression over the actor's
signals, and the optional trailing string is the failure message.

It lowers (through the only path there is — ISF → `.fsm` → SV — as a thin
`+assert` carrier) to a **clocked concurrent** SV property, guarded for
verification only and gated off during reset:

```systemverilog
`ifndef SYNTHESIS
  assert property (@(posedge clk) disable iff (!rst_n) (level < depth))
    else $error("...");
`endif
```

The clocked property samples at the clock edge (no false fires on combinational
transients) and `disable iff` suppresses it during reset — the correct semantic
for a synchronous FSM. It is **free in synthesis** (`yosys` skips it) and Verilog
(non-SV) output stays assertion-free. A signal referenced *only* by a check (e.g.
an input used just as a precondition) is kept alive as a port — it is not pruned.

A runnable example — a saturating value with an in-range invariant:

```lisp
(actor bounded
  (interface (input start) (input step (width 8)) (output done) (output count (width 8)))
  (transaction main
    (on start)
    (update count step)
    (assert (< count 200) "count must stay below 200")
    (complete done)))
```

Under simulation the assertion stays silent while `count < 200` and fires (with
the message) the moment it is violated.

`(assert …)` is the **immediate / combinational** sibling of the temporal
`(contract NAME (eventually SIGNAL within CYCLES))` (which checks a property over
a bounded number of cycles). Use `(assert …)` for "this must always hold," and a
`(contract …)` for "this must eventually happen within N cycles."

### `(cover …)` and `(assume …)`

`(assert …)` has two verification-intent siblings, lowered through the same
carrier and likewise guarded for verification only:

```lisp
(cover  (== state BUSY))            ;; was this condition ever reached?
(assume (< req_len 256) "bounded")  ;; an assumption / input constraint
```

| Form | Generated SV (clocked, `@(posedge clk) disable iff (reset)`) |
| --- | --- |
| `(assert COND [message])` | `assert property (… (COND)) else $error("message");` |
| `(assume COND [message])` | `assume property (… (COND)) else $error("message");` |
| `(cover COND [label])` | `cover property (… (COND));` |

- **`(cover …)`** records *coverage* — whether `COND` was ever true. It has no
  failure semantics (no `$error`).
- **`(assume …)`** states an *assumption* (e.g. an input constraint): in
  simulation it reports like an assert on violation; for formal tools it
  constrains the state space.

All three are the immediate/combinational verification family; choose the kind
by intent — `assert` (must always hold), `assume` (presumed to hold), `cover`
(want to observe holding).

### Temporal properties — implication `(=> A B)`

A check condition is not limited to a boolean: it may be a **temporal property**.
The workhorse is implication — "when `A`, then `B`":

```lisp
(assert (=> req ack))               ;; req |-> ack   (overlapping: same cycle)
(assert (=> (> level hi) overflow)) ;; (level > hi) |-> overflow
```

`(=> A B)` lowers to the SVA overlapping-implication operator inside the clocked
property:

```systemverilog
`ifndef SYNTHESIS
  assert property (@(posedge clk) disable iff (!rst_n) ((req) |-> (ack)))
    else $error("…");
`endif
```

Semantics (verified): when `A` is false the property is **vacuously true** (no
check); when `A` is true, `B` must hold the same cycle, else it fires. `A` and `B`
are ordinary boolean expressions (each rendered through the normal expression
path); only the `=>` combinator is special. Signals referenced only inside the
implication are kept alive as ports. A malformed `(=> A B)` (not exactly an
antecedent and a consequent) fails closed.

> This is the first piece of an ISF property sublanguage that captures what SV
> *properties* capture. Next-cycle implication (`|=>`) and bounded `(within S N)`
> (`##[1:N]`) are planned increments; once they land, the temporal
> `(contract (eventually S within N))` is expressible as `(assert (=> <trigger>
> (within S N)))` and is folded in (see `docs/decisions/0008`).

A malformed form fails closed before `.fsm` emission: e.g. `(assert)` /
`(cover)` / `(assume)` with no condition, or more than a condition + one message
string.

**Lowering**: a `+assert` carrier in the `.fsm` (each entry kind-tagged
`assert`/`cover`/`assume`) → `module_info` → the matching clocked concurrent
`<kind> property (@(posedge clk) disable iff (reset) (COND))` in the generated SV
(falling back to an immediate combinational check only if the module has no clock).

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

## Complete Accept-Path Examples

The fragments above show clause-level syntax. The four actors
below are complete, self-contained fixtures that each illustrate
one control-flow form end-to-end. Each parses and lowers cleanly,
so it can be copy-pasted as a starting skeleton.

### `(when ...)` with a body

```lisp
(actor when_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input mode)
    (output done))
  (transaction tx
    (on start)
    (when mode
      (wait 4))
    (complete done)))
```

**Walkthrough.** `(on start)` opens the transaction on the input
pulse. `(when mode (wait 4))` introduces a conditional region: the
schedule branches based on the sampled value of port `mode`. When
`mode` is asserted the schedule sits in the wait region for four
cycles; otherwise the wait body is skipped and the transaction
falls straight through to `(complete done)`. The `done` output
pulses one cycle and the transaction returns to idle.

### `(switch ...)` with `(default ...)`

```lisp
(actor switch_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input opcode (width 2))
    (output done))
  (transaction tx
    (on start)
    (switch opcode
      (0 (wait 2))
      (1 (wait 4))
      (default (wait 1)))
    (complete done)))
```

**Walkthrough.** `(input opcode (width 2))` adds a two-bit input.
`(switch opcode ...)` dispatches on the sampled value: case `0`
waits 2 cycles, case `1` waits 4 cycles, and the `default` branch
covers every other value (here `2` and `3`) with a 1-cycle wait.
The lowered decision tree negates the union of the explicit case
predicates, so the `default` branch is unreachable only when the
explicit cases are exhaustive for the signal width. All branches
exit to the same post-switch state, which here is `(complete done)`.

### `(while ...)` pre-test loop

```lisp
(actor while_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (output done))
  (transaction tx
    (on start)
    (while cond
      (wait 2))
    (complete done)))
```

**Walkthrough.** `(while cond body...)` is a pre-test loop: the
guard `cond` is evaluated *before* the first body iteration. If
`cond` is zero on entry the body never runs and the schedule
proceeds to `(complete done)`. Otherwise each iteration waits two
cycles, then the guard is re-evaluated. The body runs zero or more
times. There is no implicit counter; the loop terminates only
when `cond` becomes zero.

### `(until ...)` post-test loop

```lisp
(actor until_demo
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input cond)
    (output done))
  (transaction tx
    (on start)
    (until cond
      (wait 2))
    (complete done)))
```

**Walkthrough.** `(until cond body...)` is the post-test variant:
the body runs *first*, then the guard `cond` is checked. The body
therefore runs at least once. Iterations stop when `cond` is
asserted at the end of a body iteration. Same shape as `while`
otherwise.
