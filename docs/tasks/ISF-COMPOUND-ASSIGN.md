# ISF-COMPOUND-ASSIGN: `(incr NAME [by N])` / `(decr NAME [by N])`

## Metadata

- Tree ID: `ISF-COMPOUND-ASSIGN`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

`(incr NAME [by N])` and `(decr NAME [by N])` — the compound-assignment / increment
sugar a high-level language has (`x += N`, `x++`). They capture the common
counter/accumulator intent more clearly than `(set NAME (+ NAME N))`:

```lisp
(incr count)          ;; count += 1
(incr total by din)   ;; total += din
(decr remaining)      ;; remaining -= 1
(decr level by 2)     ;; level -= 2
```

## Ground truth

Pure ISF (IAL1) parser desugar into the existing `(set …)` data op:

```lisp
(incr x)        -> (set x (+ x 1))
(incr x by N)   -> (set x (+ x N))
(decr x)        -> (set x (- x 1))
(decr x by N)   -> (set x (- x N))
```

`(set NAME (+ NAME N))` already lowers (it is exactly the for-loop tail increment); `N`
defaults to `1` and may be a literal, signal, or expression. No new lowerer machinery.

## Design

- Parser pass `_expand_compound_assign` runs in `_build_actor` **after** the cond / for /
  let / procedure passes (so `(cond …)` → `when`-chain, `(for …)` → `repeat`, `let`/`call`
  are already expanded, and the resulting `(set …)` needs no further expansion). It walks
  clause lists, recursing into `when`/`switch`/`while`/`until`/`repeat` bodies (the lowered
  control-flow forms), and rewrites each `(incr …)`/`(decr …)` to a `(set …)`.
- `_desugar_compound` validates `(OP NAME [by N])`: a name, an optional `by N` (the `by`
  keyword then a value; default `1`); fails closed on a missing name or a malformed `by`.

## Slice plan

- `.1` select (this doc).
- `.2` the desugar: `_expand_compound_assign` + tests + docs (13e data-manipulation section,
  13k row). `(incr/decr NAME [by N])` lowers to the matching `(set …)`; malformed forms
  fail closed; verilator-clean for width-matched operands.

## Non-Goals

- Bit-set/clear or other compound ops (a possible follow-on construct).
- `(incr …)` on a non-register / read-only signal (the underlying `(set …)` already
  governs what is assignable).

## Acceptance Criteria

- `(incr NAME [by N])` / `(decr NAME [by N])` lower to `(set NAME (+ NAME N))` /
  `(set NAME (- NAME N))` (N default 1), anywhere a `(set …)` is valid (top level + control
  flow bodies); a missing name or malformed `by` fails closed; 13e documents it with a
  runnable example; audits pass. Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-COMPOUND-ASSIGN`
  Status: `done`
  Goal: `(incr/decr NAME [by N]) compound-assignment sugar — parser desugar to (set NAME (± NAME N)).`
  Children: `.1` (select), `.2` (desugar + tests + docs)

- ID: `ISF-COMPOUND-ASSIGN.1`
  Status: `done`
  Goal: `Select; desugar (incr/decr NAME [by N]) -> (set NAME (± NAME N)) in the parser.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this slice`

- ID: `ISF-COMPOUND-ASSIGN.2`
  Status: `done`
  Goal: `_expand_compound_assign desugar + tests + docs.`
  Acceptance: `(incr/decr NAME [by N]) desugars to the matching (set …); N defaults to 1 and may be a literal/signal/expression; works at the top level and in control-flow bodies; a missing name / malformed by fails closed; 13e section + 13k row; ISF_SPEC registers t/.`
  Verification: `t/1399 (3 subtests); --verify-hdl + verilator --binary on the doc accumulator (rounds=3, bonus=10); full isf regression; perl -c; mdbook build; git diff --check`
  Commit: `this slice`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | The desugar + tests + docs. |

Tree complete — `(incr/decr NAME [by N])` ships.

## Decisions

- `2026-06-01`: pure ISF parser desugar to `(set …)` (no lowerer change), running after the
  cond/for/let/proc passes so the emitted `(set …)` is final. Chosen as a quick theme-#3
  ergonomics construct after the register-reset-values tree closed (user: keep cranking
  theme-#3).

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | `t/1399` (3 subtests); `--verify-hdl` (verilator lint + yosys) on the doc accumulator; `verilator --binary` sim → `rounds=3, bonus=10`; full `prove t/` regression; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-COMPOUND-ASSIGN.1: select (incr/decr NAME [by N])` | prior slice |
| `.2` | `ISF-COMPOUND-ASSIGN.2: (incr/decr NAME [by N]) desugar + tests + docs` | this slice |

## Changelog

- `2026-06-01`: Created — `(incr/decr NAME [by N])` compound-assignment sugar, a pure ISF
  parser desugar to `(set NAME (± NAME N))`. `.2` lands the desugar + tests + docs.
- `2026-06-01`: `.2` shipped — `_expand_compound_assign` (runs after the cond/for/let/proc
  passes, recursing into `when`/`switch`/`while`/`until`/`repeat` bodies) rewrites each
  `(incr/decr NAME [by N])` to `(set NAME (± NAME N))`; `N` defaults to 1; a missing name or
  malformed `by` fails closed. t/1399 (3 subtests); 13e data-manipulation section + 13k row;
  ISF_SPEC registers t/1399. Tree closed. Noted the pre-existing two-expression-writes-per-
  register codegen constraint in the docs (the common single / in-a-loop / `by N` patterns are
  unaffected); logging it as its own core frontier item.
