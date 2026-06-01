# ISF-NESTED-COUNTED-REPEAT: Nested `(repeat …)` In A Repeat Body

## Metadata

- Tree ID: `ISF-NESTED-COUNTED-REPEAT`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Support a counted `(repeat …)` **inside** another `(repeat …)` body — the substrate for
nested loops. Today the repeat-body clause allow-list rejects `repeat`
(`unsupported '(repeat ...)' clause in repeat body`) and all repeats in a transaction share
the single counter `${tn}_cnt`, so an inner and outer repeat would collide. This tree adds
nested counted repeat with **per-instance counters**; `ISF-FOR-LOOP.6` (parser index
hoisting) then builds nested indexed `(for …)` loops on top.

```lisp
(repeat 3
  (repeat 2
    (update count (+ count 1))))   ;; body runs 3 * 2 = 6 times
```

## Ground truth (target validated by simulation, 2026-06-01)

A hand-written `.fsm` with two check-first repeats and **distinct** counters (`oc`, `ic`)
lowers and simulates correctly — body runs `3 * 2 = 6` times and terminates:

```lisp
(oinit  (<= (oc 3)) (-> ocheck))
(ocheck (-- oc) (?oc (!=0 (-> iinit)) (=0 (-> done))))   ;; outer continue enters the inner loop
(iinit  (<= (ic 2)) (-> icheck))                         ;; inner reloads each outer iteration
(icheck (-- ic) (?ic (!=0 (-> body)) (=0 (-> ocheck))))  ;; inner exit returns to the OUTER check
(body   … (-> icheck))
```

The outer body *is* the inner loop (`iinit … icheck … body`); the outer check continues to
`iinit` and the inner check returns to `ocheck`. Each repeat needs its own counter.

## Design

- Allow-list: add `repeat` to the `repeat` clause context in `%SUPPORTED_TRANSACTION_CLAUSES`.
- `_ir_repeat`: take an optional `$counter_name` (default `${tn}_cnt`, so existing top-level
  and `while`/`until`/`switch`-contained repeats are unchanged). In `_ir_repeat`'s body loop,
  add a `repeat` branch that flushes pending samples then recursively lowers the nested
  `(repeat …)` with a **unique** counter (`${tn}_cnt_<ir-ordinal>`), collecting the nested
  counter (and any deeper nested/dynamic-wait counters it returns) so they are registered in
  `+size`. The nested states splice into the outer body; the existing `_link_states` wiring
  handles them (the nested check loops back to the inner body; the outer check loops to the
  outer body's first state, which is the inner `repeat_init`).

## Slice plan

- `.1` select (this doc) + target validated by simulation.
- `.2` lowerer nested `(repeat …)`: allow-list + per-instance counter + recursive lowering
  + counter registration. Test: `(repeat 3 (repeat 2 body))` lowers, `+size` has both
  counters, simulation runs the body `M*N` times and terminates; `--verify-hdl`; isf band.

## Non-Goals

- Parser-level nested `(for …)` (index hoisting) — that is `ISF-FOR-LOOP.6`, built on `.2`.
- `while`/`until`/`when`/`switch` newly nested inside a `repeat` body beyond what already
  ships (this tree adds `repeat`-in-`repeat`).

## Acceptance Criteria

- A counted `(repeat M (repeat N body))` lowers with two distinct counters, runs `body`
  exactly `M*N` times, and terminates (proven by simulation); `--verify-hdl` passes;
  existing single/sequential repeats are unchanged (goldens stable); isf band green. Each
  leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-NESTED-COUNTED-REPEAT`
  Status: `active`
  Goal: `Nested counted (repeat …) with per-instance counters — the substrate for nested loops.`
  Children: `.1` (select + target validation), `.2` (lowerer nested-repeat support)

- ID: `ISF-NESTED-COUNTED-REPEAT.1`
  Status: `done`
  Goal: `Select; validate the nested check-first target (distinct counters) by simulation.`
  Acceptance: `Task tree committed before code; hand-written nested .fsm simulates M*N body runs + terminates.`
  Verification: `verilator --binary: hand-crafted 3x2 nested repeat -> count == 6, terminates; mdbook build; git diff --check`
  Commit: `this slice`

- ID: `ISF-NESTED-COUNTED-REPEAT.2`
  Status: `todo`
  Goal: `Lowerer nested (repeat …): allow-list + per-instance counter + recursive lowering + registration.`
  Acceptance: `(repeat M (repeat N body)) lowers (outer ${tn}_cnt + inner ${tn}_cnt_<n>, both in +size); simulation runs body M*N times + terminates; --verify-hdl PASS; single/sequential repeats unchanged; isf band PASS.`
  Verification: `Spike + t/; full isf regression; perl -c; mdbook build; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Select; target validated by simulation (3×2 → 6 body runs). |
| 2 | `.2` | `todo` | Lowerer nested-repeat: allow-list + per-instance counters + recursive lowering. |

## Decisions

- `2026-06-01`: implement nested counted repeat with per-instance counters
  (`${tn}_cnt_<ir-ordinal>` for nested instances, the bare `${tn}_cnt` kept for the
  outermost/sequential repeats so existing goldens are stable). Rides the check-first
  counted-repeat lowering (`ISF-COUNTED-REPEAT-TERMINATION`). Prerequisite for nested
  indexed `(for …)` loops (`ISF-FOR-LOOP.6`).

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | verilator `--binary`: hand-crafted nested 3×2 repeat → `count == 6`, terminates; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-NESTED-COUNTED-REPEAT.1: select + validate nested-repeat target` | this slice |

## Changelog

- `2026-06-01`: Created — nested counted `(repeat …)` with per-instance counters, the
  substrate for nested loops. Target (two check-first repeats with distinct counters)
  validated by simulation (3×2 → 6 body runs, terminates). `.2` lands the lowerer support
  (allow-list + per-instance counter + recursive lowering + registration); nested indexed
  `(for …)` (parser index hoisting) follows as `ISF-FOR-LOOP.6`.
