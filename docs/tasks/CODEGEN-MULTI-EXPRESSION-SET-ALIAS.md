# CODEGEN-MULTI-EXPRESSION-SET-ALIAS: one `<reg>_expr_en` per register aliases multiple expression `(set …)` write sites

## Metadata

- Tree ID: `CODEGEN-MULTI-EXPRESSION-SET-ALIAS`
- Status: `done`
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

## Root cause (confirmed)

`FSM/Synthesis/EnableGraph/SignalSupport.pm::generate_rhs_based_enable_name($lhs,
$rhs)` (~L757) builds the LHS-level write-enable name as
`"${clean_lhs}_${rhs_suffix}_en"`. For a complex-expression RHS it takes the
`else` branch (~L781-786): it names the expression via the `expr_namer`, then
**strips the disambiguating suffix** — `$expr_name =~ s/_expr\d*$//;` and
`s/^expr_//;` — collapsing distinct expression RHS to the same generic suffix, so
`(+ acc a)` and `(+ acc b)` both yield the LHS-level enable name `acc_expr_en`.

The per-rhs-group LHS-level enables are built in
`AssignmentSupport.pm::generate_rhs_based_enable_names` (~L685-708) — one
`lhs_level_enable.{name, ast}` per distinct `$rhs` group. With colliding names,
the two groups emit `assign acc_expr_en = …;` twice (a duplicate continuous
assign — last wins) and `build_multiplexer_config` (~L727-737) pushes both groups
into the mux / onehot0 under the **same** `enable_signal` name. The per-**state**
DT enables (e.g. `main_set_2_acc_acc_b_en`) are already distinct — only the
LHS-level name collapses.

## Fix (landed)

Make the LHS-level enable name **unique per distinct RHS group** for one register.
In `generate_rhs_based_enable_names`' per-lhs loop (`AssignmentSupport.pm` ~L681)
a `%used_enable_names` set tracks the names assigned for that register; when
`generate_rhs_based_enable_name` returns a name already used (distinct RHS
collapsing to the same suffix), the later group's name gets a numeric
discriminator (`<base>_2_en`, `<base>_3_en`, …) and the first occurrence keeps
the bare name. Every consumer (the `assign <name> = …` emission in
`EnableSupport.pm::generate_lhs_enables_from_analysis`, the mux `enable_signal`,
the `$onehot0` selector, the factorization scans) reads the stored
`lhs_level_enable.{name}`, so the rename propagates everywhere from one site.
`generate_rhs_based_enable_name` has exactly one caller, so no path regenerates a
stale name. Single-write registers never collide → identical names → zero golden
churn for the common case.

## Non-Goals

- Changing ISF surface semantics. ISF constructs that lower to expression
  `(set …)` are correct; this was purely a backend write-enable naming fix.

## Acceptance Criteria

- The `dblset` repro (two expression `(set …)`s to one register in different
  states) generates distinct per-site write-enables, applies **both** writes in
  program order across the two states, and emits a non-degenerate `$onehot0`
  selector over the distinct enables; verilator-lint + yosys clean; a functional
  testbench confirms `acc == a + b`. Full `prove t/` green (with reviewed golden
  updates). Each leaf committed via `COMMIT.md`.

## Slice plan

- `.1` select + this doc (no code). `done`.
- `.2`/`.3` per-register enable-name disambiguation + regression test
  (`t/1405`) + correction of the now-stale 13e/13k limitation notes. `done`
  (landed together — the fix was a focused per-lhs uniquifier, not a sweeping
  per-site rewrite, so one slice covered it).

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2`/`.3` | `t/1405` (2 subtests: two expression sets to one register get distinct non-aliased enables `acc_expr_en` / `acc_expr_2_en` with distinct mux arms; a single set is unchanged — bare `acc_expr_en`, no `_2_en`); witness `(set acc (+ acc a))(set acc (+ acc b))` `--verify-hdl` clean and `verilator --binary` sim → `acc == a+b == 27` (was `b == 20`, the `+a` write dropped); full `prove t/` green (no golden churn); 13e/13k limitation notes corrected to "sequential writes compose"; memory note retired | `PASS` |

## Blockers

- None. Resolved.

## Changelog

- `2026-06-02`: Created. Found while shipping `ISF-COMPOUND-ASSIGN` (two literal
  `(incr x)` in a row exposed it); confirmed pre-existing via raw double
  `(set …)`. Documented the limitation in 13e and the 13k matrix in the
  meantime; the counted-repeat lowering already avoids it by construction.
- `2026-06-02`: **fixed + closed**. Root-caused to the name collapse in
  `generate_rhs_based_enable_name` and fixed by a per-register enable-name
  uniquifier in `generate_rhs_based_enable_names`. `t/1405` guards the distinct
  wiring; the witness simulates to `acc == a+b`; full suite green with no golden
  churn. The 13e/13k notes that documented this as a limitation were corrected to
  describe sequential composing writes, and the interim memory note was retired.
  Counted-repeat no longer needs to avoid a 2nd counter expression for this
  reason (its check-first design stays for the termination fix, independently).
