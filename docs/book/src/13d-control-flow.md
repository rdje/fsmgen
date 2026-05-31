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

## Where Child Activations Are Allowed

Child-activation clauses — `(do ...)`, `(spawn ...)`, `(await_all ...)`, and
`(await_any ...)` — are accepted as **top-level transaction clauses** and **inside
a `repeat` body**. In addition, a **plain local `(do child)`** (no `(params ...)`
overrides, no `(bind ...)`, target not generated elsewhere) is accepted **directly
inside a `when` body, a `switch` branch, a `while` body, and an `until` body** —
a conditional (or loop-conditional) one-shot activation:

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
asserts the child's start handshake and blocks on its done handshake, exactly like
a top-level `(do child)`.

Still deferred (each fails closed with a targeted diagnostic) — the **generated**
and **bound** conditional activation forms:

```text
(when cond (do w (params (W 8))))     ;; deferred: generated when-body do
(when cond (do w (bind (input a r)))) ;; deferred: bound when-body do
(switch sel (0 (do w (params (W 8))))) ;; deferred: generated switch-branch do
```

For a generated/bound conditional activation today, wrap it in a `repeat` (which
accepts the generated/bound forms), e.g. `(when cond (repeat 1 (do w (params (W 8)))))`.

None of these gaps is fundamental: a `(do)` is a blocking activation, and blocking
constructs are allowed in those bodies — `(await ...)` is accepted inside `when` /
`switch` / `while` / `until`. The remaining gaps are implementation scoping: the
**local** `(do child)` is wired into all branch/loop bodies; the generated/bound
conditional forms are being added incrementally.

Across clock domains the same staging applies: a cross-domain `(do child)` through
a `(crossings (activation ...))` is supported top-level (see
[Activation Crossing](13a-actor-interface.md#activation-crossing)); a nested
cross-domain `(do)` fails closed with a "nested cross-domain activation remains
deferred" diagnostic.

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
