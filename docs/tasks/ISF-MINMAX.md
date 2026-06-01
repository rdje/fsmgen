# ISF-MINMAX: `(max DST A B)` / `(min DST A B)`

## Metadata

- Tree ID: `ISF-MINMAX`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

The min / max arithmetic-intent pair a high-level language has — pick the larger
or smaller of two values into a register (saturating counters, ceilings/floors,
priority picks):

```lisp
(max peak peak sample)   ;; peak = max(peak, sample)   (running maximum)
(min floor a b)          ;; floor = min(a, b)
```

A clamp composes directly now that sequential writes to one register work
(`CODEGEN-MULTI-EXPRESSION-SET-ALIAS`): `(max v v lo)` then `(min v v hi)`
saturates `v` into `[lo, hi]`.

## Ground truth

Pure ISF parser desugar onto the existing `(select …)` conditional assignment:

```lisp
(max DST A B) -> (select DST (>= A B) A B)
(min DST A B) -> (select DST (<= A B) A B)
```

which `_expand_selects` then expands to two mutually-exclusive conditional
`(set …)`s. `A` and `B` are any value expressions; `DST` is a register.

## Design

- A parser pass `_expand_minmax` runs in `_build_actor` **before**
  `_expand_selects`, so the emitted `(select …)` is expanded by that pass. It
  walks clause lists, recurses into control-flow bodies, and `_desugar_minmax`
  validates `(max|min DST A B)` and returns the `(select …)` rewrite.
- Fail closed: a missing / non-scalar `DST`; a missing `A` or `B`; extra operands.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_minmax` desugar + tests + docs (13e section, 13k row). `done`.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1407` (4 subtests: max/min desugar through select with `>=`/`<=`; clamp composition lowers; nested in control flow; fail-closed); the `latency (max N)` option is unaffected (`t/1093`); `--verify-hdl` (lint + yosys) clean; `verilator --binary` integration sim of `max` + a composed clamp → `max(30,70)=70`, clamp `150->80, 5->20, 50->50` (5 sequential writes to one register compose correctly); full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- A clamp/saturate construct — it composes from `(max …)` + `(min …)` (two
  sequential writes, now correct), so no dedicated form is needed.
- Min/max of more than two values — chain the construct.

## Acceptance Criteria

- `(max DST A B)` / `(min DST A B)` lower (through `(select …)`) to the two
  conditional `(set …)`s, are verilator-lint + yosys clean, and simulate
  correctly (`DST` takes the larger / smaller value); malformed forms fail closed;
  a 13e section + 13k row document them with a runnable example (a running maximum
  and a composed clamp); `ISF_SPEC` registers the t/. Each leaf committed via
  `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created. The min/max pair built on `ISF-SELECT`; a clamp composes
  from the two now that `CODEGEN-MULTI-EXPRESSION-SET-ALIAS` is fixed.
- `2026-06-02`: **shipped** — `_expand_minmax` desugar (onto `(select …)`, run
  before the select pass); `t/1407` (4 subtests), 13e Larger/Smaller-Of-Two
  section (with a composed `saturate` clamp example) + 13k row, `ISF_SPEC`
  registers `t/1407`. verilator/yosys clean; the integration sim composes a clamp
  from five sequential writes. Tree closed.
