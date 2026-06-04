# ISF-PROPERTY-WINDOW-RANGE: `(within B MIN MAX)` bounded window with a lower bound

## Metadata

- Tree ID: `ISF-PROPERTY-WINDOW-RANGE`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-04`
- Last updated: `2026-06-04`
- Owner: repo-local workflow

## Goal

Give the verification property language an explicit **lower bound** on the bounded
window: extend `(within B N)` (= `##[1:N]`, MTL `F[1,N]`) with a three-operand form
`(within B MIN MAX)` → `##[MIN:MAX]` (MTL `F[MIN,MAX]`, literal `1 <= MIN <= MAX`).
This is the `min > 1` MTL window — "the consequent holds somewhere between MIN and MAX
cycles later" — that SPECFORGE mines and that ISF could not previously spell.

Reads like:

```lisp
(assert (=> req (within ack 2 5)))   ;; (req) |-> ##[2:5] (ack)  — ack 2..5 cycles after req
```

This closes the **second** of the two deltas FSMGEN flagged to SPECFORGE in the
2026-06-04 LTL/MTL response (`docs/SPECFORGE_FEEDBACK_RESPONSE.md`); the first
(`(stable …)` + the sampled-value family) shipped in `ISF-PROPERTY-SAMPLED-VALUE.2`
(`6700fbb4`).

## Ground truth (investigated `2026-06-04`)

- The property `within` is parsed in **`FSM::Adapter::FSMGenFull::Parser::parse_check_property`**
  (`perl/FSM/Adapter/FSMGenFull/Parser.pm` ~L741): two-operand `(within X N)` →
  `{__property__=>1, op=>'within', operand=>…, bound=>N}` (literal `N >= 1`); rendered by
  **`GeneratedModuleInfoBuilder::_render_check_condition_sv`** (~L98) to `##[1:N] (X)`;
  classified **formal-only** by `_property_is_formal_only` (op `within` → 1), so it is
  emitted under `` `ifdef FORMAL ``.
- This is the **property** `within` (the `|-> ##` consequent), distinct from the
  `(monitor (within S N))` ISF construct (lowered in `LoweringIR` to arm/age/fail
  hardware, window resolved by `_resolve_monitor_window_cycles`). They do **not** share
  the FSMGenFull path, so extending the property `within` does not touch the monitor.
- ISF passes the `+assert` carrier through verbatim (`_format_isf_expr` is a pure
  serializer) — **no ISF-layer change**. The aliveness walk
  (`SignalAnalyzer::_analyze_check_condition_references`) and the formal-only walk both
  already recurse into the `operand` field.
- **SPECFORGE confirmed the contract** (`specforge/docs/FSMGEN_FEEDBACK.md`, "Answer
  (2026-06-04) — min > 1 window confirmation"): mined `cycle_window` bounds are integer
  literals; SPECFORGE guarantees `1 <= MIN <= MAX` for the `|-> ##` consequent (a `MIN=0`
  is resolved SPECFORGE-side — `[0,0]` → residual, `[0,N]` → the `(monitor …)` form).
  So **lock `(within B MIN MAX)` to `1 <= MIN <= MAX`** and fail closed on `MIN = 0`.

## Design

- Extend the `within` parser block to accept arity **2 or 3**:
  - `(within X N)` → `lower=1`, `bound=N` (unchanged; `##[1:N]`).
  - `(within X MIN MAX)` → `lower=MIN`, `bound=MAX` (new; `##[MIN:MAX]`).
  Store `lower` on the struct (default 1 for back-compat with any 2-arg / pre-existing
  struct).
- Render `##[<lower>:<bound>] (X)` (the existing renderer hardcodes `1:` — switch to the
  stored lower).
- **Validate (fail closed):** `MIN` a literal integer `>= 1`; `MAX` a literal integer
  `>= MIN`; reject `MIN = 0`, `MIN > MAX`, non-literal bounds, and the wrong arity.
- **Checkability:** a `##[MIN:MAX]` is a delay sequence → formal-only (already, via op
  `within`); no change.
- **No ISF change**; aliveness/checkability already cover `operand`.

## Slice plan

- `.1` select (this doc) — scope, ground truth (incl. SPECFORGE's confirmed contract),
  design, slice plan. Task tree committed before any code change.
- `.2` implement `(within B MIN MAX)` → `##[MIN:MAX]` — parser arity extension + render +
  fail-closed validation; 13d docs with a runnable example; 13k row + `ISF_SPEC` index;
  tests; full suite; SPECFORGE response-doc "shipped" note.

## Task Tree

- ID: `ISF-PROPERTY-WINDOW-RANGE`
  Status: `active`
  Goal: `(within B MIN MAX) -> ##[MIN:MAX] bounded window with an explicit lower bound (1 <= MIN <= MAX).`
  Children: `.1` (select), `.2` (implement)

- ID: `ISF-PROPERTY-WINDOW-RANGE.1`
  Status: `done`
  Goal: `Select; record ground truth (property within in FSMGenFull; distinct from the monitor within; ISF pass-through; SPECFORGE's confirmed 1<=MIN<=MAX contract) + design + slice plan.`
  Acceptance: `Task tree committed before any code change; TASK_TREE.md index row added.`
  Verification: `scripts/check_memory_architecture.sh; git diff --check`
  Commit: `ship commit (this slice)`

- ID: `ISF-PROPERTY-WINDOW-RANGE.2`
  Status: `pending`
  Goal: `(within B MIN MAX) renders to ##[MIN:MAX] inside assert/assume/cover; 1 <= MIN <= MAX literal, else fail closed.`
  Acceptance: `parse_check_property accepts arity-3 within (lower=MIN, bound=MAX); _render_check_condition_sv emits ##[MIN:MAX]; (within B N) unchanged (##[1:N]); formal-only; (=> req (within ack 2 5)) -> (req) |-> ##[2:5] (ack); MIN=0, MIN>MAX, non-literal bounds, wrong arity fail closed; 13d documents it with a runnable example; 13k row + ISF_SPEC focused-test index updated; a t/ test locks it; full suite green; SPECFORGE response-doc updated (min>1 shipped).`
  Verification: `prove -j4 -Iperl t/<new> t/1412 t/1376 t/1305 t/1250; --check-json on a min>1 actor; perl -c; mdbook build; full prove -j4 -Iperl t/; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc); task tree committed before code. |
| 2 | `.2` | `pending` | Arity-3 `within` parser + `##[MIN:MAX]` render + fail-closed validation + synced docs + tests. |

## Decisions

- `2026-06-04`: spell the lower bound as a **third operand on the existing `within`**
  (`(within B MIN MAX)`) rather than a new combinator — backward-compatible, and it is
  exactly SPECFORGE's `(window <min> <max>)` modifier.
- `2026-06-04`: lock `1 <= MIN <= MAX` (SPECFORGE-confirmed it never emits `MIN = 0` as a
  `|-> ##` consequent); `MIN = 0` fails closed — `[0,0]` and `[0,N]` are the residual /
  `(monitor …)` cases, not this consequent.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-04` | `.1` | `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-PROPERTY-WINDOW-RANGE.1: select — (within B MIN MAX) bounded-window lower bound (task tree)` | `ship commit (this slice)` |

## Changelog

- `2026-06-04`: Created. Selected adding an explicit lower bound to the bounded-window
  property — `(within B MIN MAX)` → `##[MIN:MAX]` — the `min > 1` MTL window SPECFORGE
  mines, closing the second of the two deltas FSMGEN flagged in the 2026-06-04 LTL/MTL
  response. SPECFORGE confirmed (its `FSMGEN_FEEDBACK.md` 2026-06-04 answer) that mined
  bounds are integer literals with a guaranteed `1 <= MIN <= MAX` for the `|-> ##`
  consequent, so the form is locked to that range. Recorded ground truth (the property
  `within` lives in `FSMGenFull::Parser`, distinct from the `(monitor …)` window; ISF
  passes the carrier through verbatim) and the slice plan.
