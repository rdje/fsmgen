# ISF-SELECT: `(select DST COND A B)` conditional assignment

## Metadata

- Tree ID: `ISF-SELECT`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

The conditional assignment / two-way select a high-level language writes as
`dst = cond ? a : b` — pick one of two values for a register by a condition:

```lisp
(select out (> level hi) MAX level)   ;; out = (level > hi) ? MAX : level
(select dst pick a b)                 ;; dst = pick ? a : b
```

Unblocked by `CODEGEN-MULTI-EXPRESSION-SET-ALIAS` (the two conditional writes to
`DST` previously aliased to one write-enable; now each gets its own).

## Ground truth

Pure ISF parser desugar into two mutually-exclusive conditional `(set …)`s:

```lisp
(select DST COND A B) -> (when COND     (set DST A))
                         (when (! COND)  (set DST B))
```

`COND` is any condition expression (scalar or list); `A` and `B` are any value
expressions; `DST` is a register. The two `(when …)` lower to two sequential
decision states — `DST` takes `A` on the true path and `B` on the false path
(exactly one fires). No width resolution or sized literals are needed.

## Design

- A parser pass `_expand_selects` runs in `_build_actor` after the cond/for/let/
  proc passes (so the emitted `(when …)`/`(set …)` are final), walking clause
  lists and recursing into control-flow bodies. `_desugar_select` validates the
  `(select DST COND A B)` shape and returns the two `(when …)` clauses (spliced
  into the clause list, like the `cond` desugar).
- Fail closed: a missing / non-scalar `DST`; a missing `COND`, `A`, or `B`; or
  extra operands.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_selects` desugar + tests + docs (13e section, 13k row). `done`.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1406` (4 subtests: two conditional sets; expression cond + value expressions preserved; nested in a control-flow body; fail-closed too-few / too-many / no-name); `--verify-hdl` (lint + yosys) clean; `verilator --binary` sim of the `clamp` example → `x=150 -> 100`, `x=42 -> 42`; full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- A single-cycle combinational mux — `.fsm` has no ternary operator, so the
  construct lowers to two sequential conditional writes (two states). Documented.
- A multi-way select (that is `(cond …)` / `(switch …)`).

## Acceptance Criteria

- `(select DST COND A B)` lowers to the two documented conditional `(set …)`s, is
  verilator-lint + yosys clean, and simulates correctly (`DST` takes `A` when
  `COND`, else `B`); malformed forms fail closed; a 13e section + 13k row document
  it with a runnable example; `ISF_SPEC` registers the t/. Each leaf committed via
  `COMMIT.md`.

## Blockers

- None (the enabling codegen fix `CODEGEN-MULTI-EXPRESSION-SET-ALIAS` has landed).

## Changelog

- `2026-06-02`: Created. Conditional assignment, freshly unblocked by the
  multi-expression-set-alias fix — spiked `(when pick (set dst a))(when (! pick)
  (set dst b))` and it simulates correctly (`pick=1 -> a`, `pick=0 -> b`),
  verilator/yosys clean.
- `2026-06-02`: **shipped** — `_expand_selects` desugar; `t/1406` (4 subtests),
  13e Conditional Assignment section + 13k row, `ISF_SPEC` registers `t/1406`. The
  `clamp` example is verilator/yosys clean and simulates correctly. Tree closed.
