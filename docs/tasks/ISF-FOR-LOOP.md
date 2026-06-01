# ISF-FOR-LOOP: `(for (i N) body)` Indexed Counted Loop

## Metadata

- Tree ID: `ISF-FOR-LOOP`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

`(for (i N) body...)` — an **indexed** counted loop. It runs `body` exactly `N` times
while exposing a loop index `i` that counts `0, 1, … N-1` to the body, so the body can
do indexed work (addressing, per-iteration values) that bare `(repeat N body)` cannot.
This is the ergonomic indexed-loop sugar a high-level language has; it desugars entirely
in the ISF parser (IAL1) into constructs that already lower — no new lowerer machinery.

```lisp
(for (i 4)
  (update result (+ result i)))   ;; i = 0,1,2,3 across the four iterations
```

## Ground truth (desugar target already lowers)

`(for (i N) body)` desugars to a declared internal index register plus a counted
`(repeat)` that increments the index at the tail of each iteration:

```lisp
(local i (width W) (default 0))           ;; W = bits to hold N (so the final i=N doesn't wrap)
(repeat N
  body...
  (set i (+ i 1)))                         ;; index advances 0 -> 1 -> … -> N
```

Read-only spike confirmed this target LOWERS cleanly: `i` appears in `+size`, the
increment is emitted, and `--check-json` / `--verify-hdl` pass. Both `(local …)`
(`ISF-LOCAL-VARIABLES`) and `(repeat N …)` with a `(set …)` body are existing,
exercised constructs — `for` is pure parser desugar, mirroring `(let …)` / `(call …)`
expansion (`_expand_let_bindings` / `_expand_procedure_calls`).

- `(local …)` is allowed **only** in the `transaction` clause context
  (`%SUPPORTED_TRANSACTION_CLAUSES`), so the desugared index declaration must sit at the
  transaction top level. Therefore `.2` supports a **top-level** `(for …)`; a
  nested/embedded `(for …)` (inside `when`/`while`/`until`/`repeat`/`switch` or another
  `for`) fails closed with a clear top-level-only diagnostic (lifting that restriction —
  hoisting indices to the transaction top — is a later slice).
- Width auto-sizing: `W = length(sprintf "%b", N)` — bits to represent `N`, so the
  index can reach `N` after the final increment without wrapping. `.2` requires a
  **literal** non-negative integer `N` (explicit-width / param-count forms are a later
  slice).

## Design

- Parser pass `_expand_for_loops` runs in `_build_actor` **before** `_expand_let_bindings`
  and `_expand_procedure_calls`, so any `(let …)` / `(call …)` inside a `for` body is
  expanded afterwards (it now lives inside the desugared `(repeat …)`, which both passes
  already recurse into).
- `_expand_fors_in_list($clauses, $ctx, $top)` walks a clause list. A top-level `(for …)`
  is replaced by `_desugar_for` (two clauses: the `(local …)` index + the `(repeat …)`).
  Control-flow clauses recurse with `$top = 0`. A `(for …)` reached with `$top = 0` fails
  closed (top-level-only).
- `_desugar_for` validates the `(VAR COUNT)` spec (name + literal `N >= 1`, non-empty
  body), auto-sizes `W`, and emits `[(local VAR (width W) (default 0)),
  (repeat N body… (set VAR (+ VAR 1)))]`. The body is itself for-expanded (so a nested
  `(for …)` inside it is detected and fails closed).

## Slice plan

- `.1` select (this doc).
- `.2` top-level `(for (i N) body)` with literal `N`, auto-sized index — the parser
  desugar; golden `.fsm` + `--check-json` + `--verify-hdl`; nested/embedded `for` fails
  closed; `t/`; docs (13d section + example, 13k row, ISF_SPEC registers the test).
- `.3` (frontier) lift restrictions: index hoisting so `(for …)` nests and embeds in
  control flow, and explicit-width / non-literal (param/constant) counts.

## Non-Goals

- Reverse / step / range (`from`/`to`/`by`) loops — a later construct if wanted.
- Multi-variable `for`.
- `(for …)` inside a `(proc …)` body (inline substitution would duplicate the index
  declaration) — deferred.

## Acceptance Criteria

- A top-level `(for (i N) body)` with literal `N` lowers: `i` is a declared internal
  register counting `0 … N-1` across `N` iterations of `body`, with golden `.fsm` +
  `--check-json` + `--verify-hdl`; a malformed spec and a nested/embedded `for` fail
  closed with clear diagnostics; 13d documents it with a runnable example; audits pass.
  Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-FOR-LOOP`
  Status: `active`
  Goal: `(for (i N) body) indexed counted loop — parser desugar into a declared index local + counted repeat with a tail increment.`
  Children: `.1` (select), `.2` (top-level literal-N desugar), `.3` (frontier: nesting/embedding + explicit-width/param counts)

- ID: `ISF-FOR-LOOP.1`
  Status: `done`
  Goal: `Select; desugar (for (i N) body) -> (local i …) + (repeat N body (set i (+ i 1))) in the parser, mirroring let/proc expansion. Top-level literal-N for .2 (local is transaction-context only).`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.2`
  Status: `done`
  Goal: `Top-level (for (i N) body) with literal N — parser desugar.`
  Acceptance: `_expand_for_loops runs before let/proc expansion; a top-level (for (i N) body) desugars to (local i (width W) (default 0)) + (repeat N body… (set i (+ i 1))) with W = bits to hold N; i counts 0..N-1 to the body; nested/embedded (for …) and a non-literal/empty/<1 count fail closed with clear diagnostics; --check-json SUCCESS. 13d gains a (for …) section + example; 13k row; ISF_SPEC registers t/1394.`
  Verification: `(for (i 4) (update result (+ result i))) lowers: i in +size at width 3, init (i 0), body reads i, tail (set i (+ i 1)), check-first repeat. Simulated (verilator --binary): terminates, result == 0+1+2+3 == 6 (i = 0..3 across exactly 4 iterations). --check-json SUCCESS. Fail-closed: non-literal/zero count, empty body, nested for, for-in-when. prove -Iperl t/1394 (4 subtests) + t/1250 t/1305 t/1304 t/1307 t/1376 PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.3`
  Status: `done`
  Goal: `Explicit-width index + non-literal counts: (for (i (width W) COUNT) body) where COUNT may be a literal, parameter, constant, or runtime scalar.`
  Acceptance: `(for (i (width W) N) body) declares the index at width W and passes COUNT to the counted (repeat …) (which accepts literal/param/constant/runtime counts); i counts 0..COUNT-1; COUNT==0 (runtime) runs zero times. A zero width, a literal-zero count, an implicit-width non-literal count, and an empty body fail closed with clear diagnostics. The implicit (for (i N) …) literal form is unchanged. t/1394 gains explicit-width subtests; 13d + 13k document the form.`
  Verification: `(for (i (width 8) n) (update total (+ total i))) lowers (i width 8; repeat loads n once -> check); simulated (verilator --binary) n=5 -> total==10 (i=0..4), n=1 -> 0, n=0 -> 0 iterations. Fail-closed: (width 0), literal (width 8) 0, implicit (i n). prove -Iperl t/1394 (6 subtests) + doc gates PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.4`
  Status: `done`
  Goal: `Range form (for (i from A to B) body): the index counts A..B-1 (B-A iterations) starting at A.`
  Acceptance: `(for (i from A to B) body) with literal A, B and B > A desugars to (local i (width W) (default A)) + (repeat (B-A) body… (set i (+ i 1))); i counts A..B-1; the upper bound B is exclusive; width auto-sizes to hold B. A descending/empty range (B <= A), non-literal bounds, and a missing 'to' fail closed with clear diagnostics. t/1394 gains range subtests; 13d + 13k document the form.`
  Verification: `(for (i from 2 to 5) (update total (+ total i))) lowers (i default 2, count 3, width 3); simulated (verilator --binary) total == 9 (i=2,3,4), terminates. Fail-closed: B<=A, B==A, non-literal bounds, missing 'to'. prove -Iperl t/1394 (8 subtests) + doc gates PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.5`
  Status: `done`
  Goal: `Range step form (for (i from A to B step S) body): strided iteration i = A, A+S, … < B.`
  Acceptance: `A trailing 'step S' (literal S >= 1, default 1) makes the range stride by S: ceil((B-A)/S) iterations counting i = A, A+S, A+2S, … (each < B), with (set i (+ i S)) as the tail increment and the width sized to hold the post-final-increment value. A zero/non-literal step and a non-'step' trailer fail closed. t/1394 gains step subtests; 13d + 13k document it.`
  Verification: `(for (i from 0 to 10 step 2) (update total (+ total i))) lowers (count 5, default 0, +2 increment); simulated (verilator --binary) total == 20 (i=0,2,4,6,8), terminates; (from 1 to 10 step 3) -> count 3 (i=1,4,7). Fail-closed: step 0, non-literal step, non-'step' trailer. prove -Iperl t/1394 (10 subtests) + doc gates PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.6`
  Status: `done`
  Goal: `Nested (for …): a (for …) directly inside another (for …) body — nested indexed loops.`
  Acceptance: `(for (i M) (for (j N) body)) desugars with BOTH index (local …) declarations hoisted to the transaction top, an inner-index reset (set j START) at the head of each outer iteration, and a nested counted (repeat …) (riding ISF-NESTED-COUNTED-REPEAT, so the inner/outer counters are distinct); the body runs M*N times with independent indices. _desugar_for returns (hoisted_locals, replacement) and expands its body via _expand_for_body (which hoists directly-nested fors' locals). Single for-loops (count/width/range/step) are unchanged. A (for …) embedded in a when/switch/while/until/repeat body still fails closed (deferred to .7). t/1394 gains a nested-for subtest; 13d + 13k document nested for.`
  Verification: `(for (i 3) (for (j 2) (update grid (+ grid (+ i j))))) lowers (i, j hoisted to +size; main_cnt + main_cnt_<n>; (set j 0) reset; i,j tail increments); verilator --binary -> grid == 9 (i=0..2, j=0..1), terminates. Single for-loops + range/step unchanged; embedded for-in-when fails closed. prove -Iperl t/1394 (11 subtests) + doc gates PASS; full suite PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-FOR-LOOP.7`
  Status: `frontier`
  Goal: `Embedded (for …): a (for …) inside a when/switch/while/until/repeat body (the local already hoists; bubble it past the enclosing control flow + reset correctly when the for is inside a looping context).`
  Acceptance: `TBD when scheduled.`
  Verification: `TBD`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | Top-level `(for (i N) body)`, literal `N`, auto-sized index — parser desugar into `(local i …)` + counted `(repeat …)` with a tail increment. Simulated exactly-N with `i = 0..N-1`. |
| 3 | `.3` | `done` | Explicit-width index + non-literal counts: `(for (i (width W) COUNT) body)` (param/constant/runtime counts). Simulated runtime n=5 → sum 0..4 == 10. |
| 4 | `.4` | `done` | Range form `(for (i from A to B) body)` — index counts A..B-1. Simulated `(from 2 to 5)` → sum 2+3+4 == 9. |
| 5 | `.5` | `done` | Range step form `(for (i from A to B step S) body)` — strided iteration. Simulated `(from 0 to 10 step 2)` → sum 0+2+4+6+8 == 20. |
| 6 | `.6` | `done` | Nested `(for (i M) (for (j N) body))` — index hoisting + nested counted repeat. Simulated 3×2 → sum(i+j) == 9. |
| 7 | `.7` | `frontier` | Embedded `(for …)` in a control-flow body (when/switch/while/until/repeat). |

## Decisions

- `2026-06-01`: implement as a pure ISF (IAL1) parser desugar — `(for (i N) body)` ->
  `(local i (width W) (default 0))` + `(repeat N body… (set i (+ i 1)))` — reusing
  `(local …)` and counted `(repeat …)`, both of which already lower. No lowerer change.
  `.2` scoped top-level + literal `N` because `(local …)` is transaction-context only;
  nesting/embedding and param counts are the `.3` frontier. Chosen as the next theme-#3
  construct (after `ISF-LOOP-CONTINUE`).

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | `(for (i 4) …)` lowers (index in `+size`, init 0, body reads `i`, tail increment, check-first repeat); `verilator --binary` → terminates, `result == 6` (`i = 0..3`, exactly 4 iterations); `--check-json` SUCCESS; non-literal/zero/empty/nested/embedded fail closed. `prove -Iperl t/1394 t/1250 t/1305 t/1304 t/1307 t/1376` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.3` | `(for (i (width 8) n) …)` lowers (i width 8; repeat loads runtime `n` once → check); `verilator --binary` → n=5 → total==10 (`i=0..4`), n=1 → 0, n=0 → 0 iterations; fail-closed: zero width, literal-zero count, implicit-width non-literal. `prove -Iperl t/1394` (6 subtests) + doc gates PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.4` | `(for (i from 2 to 5) …)` lowers (i default 2, count 3, width 3, tail increment); `verilator --binary` → total==9 (`i=2,3,4`), terminates; fail-closed: B<=A, B==A, non-literal bounds, missing 'to'. `prove -Iperl t/1394` (8 subtests) + doc gates PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.5` | `(for (i from 0 to 10 step 2) …)` lowers (count 5, default 0, `+2` increment); `verilator --binary` → total==20 (`i=0,2,4,6,8`), terminates; `(from 1 to 10 step 3)` → count 3 (`i=1,4,7`); fail-closed: step 0, non-literal step, non-'step' trailer. `prove -Iperl t/1394` (10 subtests) + doc gates PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.6` | `(for (i 3) (for (j 2) (update grid (+ grid (+ i j))))) ` lowers (i, j hoisted to `+size`; `main_cnt` + `main_cnt_<n>`; `(set j 0)` inner reset; i/j tail increments); `verilator --binary` → grid==9 (`i=0..2, j=0..1`), terminates; single for + range/step unchanged; embedded for-in-when fails closed. `prove -Iperl t/1394` (11 subtests) + doc gates PASS; full suite PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-FOR-LOOP.1: select (for (i N) body) indexed counted loop` | committed |
| `.2` | `ISF-FOR-LOOP.2: (for (i N) body) indexed counted loop desugar` | committed |
| `.3` | `ISF-FOR-LOOP.3: (for (i (width W) COUNT) body) explicit-width + non-literal counts` | `0b2405aa` |
| `.4` | `ISF-FOR-LOOP.4: (for (i from A to B) body) range form` | `eb693153` |
| `.5` | `ISF-FOR-LOOP.5: (for (i from A to B step S) body) range step form` | `217fa0c5` |
| `.6` | `ISF-FOR-LOOP.6: nested (for (i M) (for (j N) body)) via index hoisting` | this slice |

## Changelog

- `2026-06-01`: Created as the next theme-#3 (intent-capture) construct — `(for (i N)
  body)` indexed counted loop. Pure ISF parser desugar into a declared index `(local …)`
  + counted `(repeat …)` with a tail increment, mirroring `(let …)` / `(call …)`
  expansion; no lowerer machinery. `.2` lands the top-level literal-`N` form (the index
  `(local …)` must sit at the transaction top because `local` is transaction-context
  only); `.3` is the frontier for nesting/embedding (index hoisting) and
  explicit-width / param counts.
- `2026-06-01`: `.2` shipped — the parser desugar landed (`_expand_for_loops` runs before
  `let`/procedure expansion). `(for (i N) body...)` → `(local i (width W) (default 0))` +
  `(repeat N body... (set i (+ i 1)))`, `W` = bits to hold `N`, `i` 0-based. Verified by
  simulation (`verilator --binary`): `(for (i 4) (update result (+ result i)))` terminates
  with `result == 6` (`i = 0,1,2,3` across exactly four iterations) — correct because it
  rides the fixed counted-`(repeat …)` lowering (`ISF-COUNTED-REPEAT-TERMINATION.2`).
  Nested/embedded `(for …)`, a non-literal or zero count, and an empty body fail closed
  with clear diagnostics. `t/1394` (4 subtests); `13d` gains a `(for …)` section; the
  `13k` control-flow row lists it; `docs/ISF_SPEC.md` registers `t/1394`.
- `2026-06-01`: `.3` shipped — explicit-width index + non-literal counts.
  `(for (i (width W) COUNT) body)` declares the index at width `W` (positive literal) and
  passes `COUNT` to the counted `(repeat …)`, so `COUNT` may be a literal, actor/transaction
  parameter, package/actor constant, or known-width runtime scalar — the indexed
  variable-count loop. Verified by simulation: `(for (i (width 8) n) (update total
  (+ total i)))` runs `n` times with `i = 0..n-1` (n=5 → total 10, n=0 → zero iterations).
  A zero width, a literal-zero count, an implicit-width non-literal count, and an empty
  body fail closed. The implicit `(for (i N) …)` literal form is unchanged. `t/1394` gains
  two explicit-width subtests (6 total); `13d`/`13k` document the form. Nesting/embedding
  (index hoisting) moves to a later slice (it needs nested-counted-repeat support, since
  nested for-loops desugar to nested `(repeat …)` which the allow-list currently rejects).
- `2026-06-01`: `.4` shipped — the range form `(for (i from A to B) body)`. The index
  counts `i = A, A+1, … B-1` (`B-A` iterations, upper bound `B` exclusive) starting at `A`;
  it desugars to `(local i (width W) (default A))` + `(repeat (B-A) body… (set i (+ i 1)))`
  with `W` sized to hold `B`. `A`, `B` are literal non-negative integers with `B > A`.
  Verified by simulation: `(for (i from 2 to 5) (update total (+ total i)))` → `total == 9`
  (`i = 2,3,4`), terminates. A descending/empty range (`B <= A`), non-literal bounds, and a
  missing `to` fail closed. `t/1394` gains two range subtests (8 total); `13d`/`13k`
  document the form. Nesting/embedding moves to a later slice.
- `2026-06-01`: `.5` shipped — the range step form `(for (i from A to B step S) body)`.
  A trailing `step S` (literal `S >= 1`, default `1`) strides the index: `ceil((B-A)/S)`
  iterations counting `i = A, A+S, A+2S, …` (each `< B`), desugaring with `(set i (+ i S))`
  as the tail increment and the width sized to hold the post-final-increment value.
  Verified by simulation: `(for (i from 0 to 10 step 2) (update total (+ total i)))` →
  `total == 20` (`i = 0,2,4,6,8`), terminates; `(from 1 to 10 step 3)` → 3 iterations
  (`i = 1,4,7`). A zero/non-literal step and a non-`step` trailer fail closed. `t/1394`
  gains two step subtests (10 total); `13d`/`13k` document it. Nesting/embedding moves
  to `.6`.
- `2026-06-01`: `.6` shipped — **nested for-loops**. A `(for …)` directly inside another
  `(for …)` body now lowers: `_desugar_for` returns `(hoisted_locals, replacement)` and
  expands its body via `_expand_for_body`, which desugars a directly-nested `(for …)` and
  hoists its index `(local …)` up. So `(for (i M) (for (j N) body))` emits both index locals
  at the transaction top, an inner-index reset `(set j START)` at the head of each outer
  iteration, and a nested counted `(repeat …)` — riding `ISF-NESTED-COUNTED-REPEAT` so the
  inner/outer counters are distinct (`main_cnt` + `main_cnt_<n>`). Verified by simulation:
  `(for (i 3) (for (j 2) (update grid (+ grid (+ i j)))))` → `grid == 9` (`i=0..2, j=0..1`),
  terminates. Single for-loops (count/width/range/step) are unchanged. A `(for …)` embedded
  in a `when`/`switch`/`while`/`until`/`repeat` body still fails closed (the index would have
  to bubble past the enclosing control flow) — deferred to `.7`. `t/1394` gains a nested-for
  subtest (11 total); `13d`/`13k` document nested for.
