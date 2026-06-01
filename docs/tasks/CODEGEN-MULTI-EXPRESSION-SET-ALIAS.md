# CODEGEN-MULTI-EXPRESSION-SET-ALIAS: one `<reg>_expr_en` per register aliases multiple expression `(set …)` write sites

## Metadata

- Tree ID: `CODEGEN-MULTI-EXPRESSION-SET-ALIAS`
- Status: `active`
- Roadmap lane: core HDL codegen (EnableGraph synthesis) — not R14/ISF
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Summary

When one register is written by **two or more expression `(set …)`s in different
states of one transaction**, the EnableGraph backend generates a single
register-keyed expression write-enable wire `<reg>_expr_en` and assigns it once
per write site — every assignment aliasing to the **last** writer's enable. The
result is a silent functional bug: all but the last expression-set are dropped,
and the generated multi-driver `$onehot0` assertion degenerates to listing the
same wire N times (always true), so it no longer detects the conflict.

This is **pre-existing** and **not** specific to any ISF surface construct — raw
`(set …)` hits it directly. `(incr/decr …)`, `(update …)`, the for-loop tail
increment, etc. all lower to expression `(set …)` and so inherit it. The common
shapes are unaffected: a register written by a single expression-set, or by an
expression-set inside a loop body (one state executed N times → one write site).

The ISF lowering layer already works **around** this limitation in at least one
place — counted-repeat (`ISF-COUNTED-REPEAT-TERMINATION`) deliberately loads its
counter with a raw copy and keeps the per-iteration decrement as the counter's
*only* expression-assignment, precisely so two expression writes do not alias to
one `<counter>_expr_en` (see `LoweringIR.pm` ~L4753-4760).

## Repro

```lisp
(actor dblset
  (interface (input start) (input a (width 8)) (input b (width 8))
             (output done) (output acc (width 8)))
  (transaction main
    (on start)
    (set acc (+ acc a))
    (set acc (+ acc b))
    (complete done)))
```

Generated SystemVerilog (abridged) shows the alias:

```systemverilog
wire acc_expr_en;
assign acc_expr_en = main_set_2_acc_acc_b_en;   // write site 1 (+ acc a) ...
assign acc_expr_en = main_set_2_acc_acc_b_en;   // ... aliased to write site 2 (+ acc b)
if (acc_expr_en) begin ... end                  // both next-value arms gate on the same enable
assert ($onehot0({acc_expr_en, acc_expr_en}))   // degenerate: same wire twice, always true
  else $error("selector multi-value conflict: acc");
```

`acc` only ever receives `acc + b`; the `acc + a` set is silently lost.
`verilator --lint` and `yosys` both PASS because a duplicate *identical*
continuous assign is not a structural multi-driver — so neither external tool
catches it. Only functional simulation (or reading the generated wiring) reveals
the dropped write.

## Root cause (to confirm)

The expression write-enable wire is named per **register** (`lc(type) . "_expr"`
+ `_en` in `FSM/Synthesis/EnableGraph/` — see `SignalSupport.pm` ~L124,
`CaptureSupport.pm` ~L879, and `HDL/ASTFactorization.pm` ~L622) rather than per
**write site / state**. Two expression-set states for the same register collide
on that one wire; the last `assign` wins, and the onehot0 selector is built from
the same (register-keyed) name list.

## Proposed direction (design, not yet committed)

Give each expression write site its own enable (e.g. `<reg>_expr_en_<state>` or
reuse the per-state `<state>_<reg>_..._en` already generated), drive the
register's next-value mux by selecting among the **distinct** per-site enables,
and build the `$onehot0` selector from those distinct enables so it once again
detects a true same-cycle multi-write. Must stay backward-compatible with the
single-expression-set case (no churn for the overwhelmingly common shape) and
keep verilator-lint + yosys clean. Expect golden-output updates across the suite.

## Non-Goals

- Changing ISF surface semantics. ISF constructs that lower to expression
  `(set …)` are correct; this is purely a backend write-enable naming/selection
  fix. The ISF docs (13e) describe the limitation in the meantime.

## Acceptance Criteria

- The `dblset` repro (two expression `(set …)`s to one register in different
  states) generates distinct per-site write-enables, applies **both** writes in
  program order across the two states, and emits a non-degenerate `$onehot0`
  selector over the distinct enables; verilator-lint + yosys clean; a functional
  testbench confirms `acc == a + b`. Full `prove t/` green (with reviewed golden
  updates). Each leaf committed via `COMMIT.md`.

## Slice plan

- `.1` select + this doc (no code).
- `.2` characterization test capturing the current broken wiring as the bug
  witness (xfail / documented-current-behavior), so the fix has a target.
- `.3` per-write-site enable generation in EnableGraph + golden updates; the
  repro applies both writes; multi-driver detection restored.

## Blockers

- None — but it is a core-backend change with broad golden impact; sequence it
  deliberately rather than mid-ISF-theme. Logged now so it is tracked.

## Changelog

- `2026-06-02`: Created. Found while shipping `ISF-COMPOUND-ASSIGN` (two literal
  `(incr x)` in a row exposed it); confirmed pre-existing via raw double
  `(set …)`. Documented the limitation in 13e and the 13k matrix in the
  meantime; the counted-repeat lowering already avoids it by construction.
