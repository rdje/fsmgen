# ISF-COVER-ASSUME: `(cover COND [label])` / `(assume COND [message])`

## Metadata

- Tree ID: `ISF-COVER-ASSUME`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

The verification-intent siblings of `(assert COND)` (`ISF-ASSERT`):

```lisp
(cover  (== state BUSY))           ;; coverage: was this ever reached?
(assume (< req_len 256) "bounded") ;; assumption: constrain inputs (formal)
```

- **`(cover COND [label])`** → a verification-only `cover (COND);` (coverage —
  did `COND` ever hold?). No failure semantics.
- **`(assume COND [message])`** → a verification-only `assume (COND) else
  $error("message");` (an assumption / input constraint; in simulation it reports
  like an assert, for formal it constrains).

## Design — generalise the immediate-check family (one `kind`)

Reuse the `ISF-ASSERT` machinery by adding a `kind` ∈ `{assert, cover, assume}` to
each immediate-check record (rather than parallel `+cover`/`+assume` machinery):

- **ISF lowerer**: `cover` / `assume` join `assert` in the transaction clause
  allow-list; the collector (`_ir_check`, generalised from `_ir_assert`) reads the
  clause head as the kind and emits a record `{ name <tx>_<kind>_<n>, kind,
  condition, message }`.
- **`.fsm` carrier**: the `+assert` section entries gain the kind —
  `(NAME KIND COND ["msg"])` (kind always emitted, so no ambiguity). FSMGenFull
  parses the kind (validated ∈ the three) onto
  `$fsm_module->{attributes}{immediate_assertions}` records.
- **module_info / emitter**: the surfaced record carries `kind`; the emitter
  branches — `assert`/`assume` → `<kind> (COND) else $error("msg")`, `cover` →
  `cover (COND);` — all under `` `ifndef SYNTHESIS `` (Verilog stays
  assertion-free). The keep-alive (`SignalAnalyzer`) is unchanged (it walks every
  immediate-check condition regardless of kind).

## Slice plan

- `.1` select (this doc).
- `.2` generalise the immediate-check family to carry `kind`; add `cover` +
  `assume`; update emit/parse/surface/runtime-lines; tests (`t/1410`/`t/1411`
  extended + cover/assume cases); docs (13d + 13k); verify-hdl + `verilator
  --binary` (cover counts a hit; assume fires on violation).

## Non-Goals

- Concurrent/temporal `cover property` / `assume property` (`|->`) — that is the
  `(contract …)` territory; these are immediate/combinational.

## Acceptance Criteria

- `(cover …)` emits `cover (COND);` and `(assume …)` emits `assume (COND) else
  $error(…)`, both verification-only; verilator-lint + yosys clean; Verilog
  assertion-free; `(assert …)` unchanged and still green; malformed forms fail
  closed; 13d/13k document them; `ISF_SPEC` test registration current. Full suite
  green; committed via `COMMIT.md`.

## Blockers

- None — builds directly on the landed `ISF-ASSERT` immediate-check pipeline.

## Changelog

- `2026-06-02`: Created at the user's request ("-> cover, assume"). Generalises the
  `ISF-ASSERT` immediate-check infrastructure with a `kind` field rather than
  duplicating it.
