# ISF-BIT-TEST: `(when-bit NAME N body…)` / `(unless-bit NAME N body…)`

## Metadata

- Tree ID: `ISF-BIT-TEST`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

The read side of single-bit register intent — branch on a status / config /
flag bit. Completes the bit story (`ISF-BIT-OPS` sets/clears/toggles; this tests):

```lisp
(when-bit   ctrl 0  (start-engine))   ;; run body when ctrl[0] == 1
(unless-bit irq  3  (idle))           ;; run body when irq[3]  == 0
```

A statement (clause) form rather than a guard-expression predicate, so it is a
clean clause-level desugar (no expression-tree walking) — it reads "when bit N of
NAME is set, do …".

## Ground truth

Pure ISF parser desugar into a `(when …)` with an explicit, width-qualified
masked comparison (the spike showed an unsized literal mask / multi-bit
truthiness produces WIDTHEXPAND **and** a functional miss; a sized literal with
an explicit `!=`/`==` against a sized zero is verilator-lint + yosys clean and
correct):

```lisp
(when-bit   x N body…) -> (when (!= (& x W'dMASK) W'd0) body…)   ; MASK = 2^N
(unless-bit x N body…) -> (when (== (& x W'dMASK) W'd0) body…)
```

`N` is a literal bit index, `0 <= N < W`, where `W` is the register's declared
literal width (resolved from a `(local …)`, an interface port, or a
`(storage (var …))`). The sized literals (`W'd…`) need `W`, so a non-literal /
symbolic width fails closed (as `clear-bit` does).

## Design

- A parser pass `_expand_bit_tests` runs in `_build_actor` **after** the
  cond/for/let/proc passes (so the body holds lowered control-flow forms) but
  **before** `_expand_compound_assign` / `_expand_bit_ops`, so those passes'
  `(when …)` recursion still reaches the desugared body (an `(incr …)` /
  `(set-bit …)` inside a `(when-bit …)` body must still expand). It reuses the
  `_bit_op_width_map` resolver and recurses into `when`/`while`/`until`/`repeat`/
  `switch` bodies **and** into `when-bit`/`unless-bit` bodies (nested tests).
- Fail closed: a missing name; a missing / non-integer / multiple bit index; an
  index `>= W`; an empty body; and a non-literal / symbolic width.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_bit_tests` desugar + tests + docs (13e/13d section, 13k row). `done`.

## Implementation

- `Parser.pm`: `_expand_bit_tests` runs in `_build_actor` after cond/for/let/proc
  and before `_expand_compound_assign`/`_expand_bit_ops` (so their `(when …)`
  recursion reaches the desugared body). It reuses `_bit_op_width_map`.
  `_desugar_bit_test` validates the form, **expands its own body** via
  `_expand_bit_tests_in_list` (so a nested `(when-bit …)` desugars), then wraps
  it in `(when (CMP (& NAME W'dMASK) W'd0) body…)` (`!=` for `when-bit`, `==` for
  `unless-bit`). `_bit_test_rewrite_clause` recurses into when/while/until/repeat/
  switch bodies for tests sitting inside other control flow.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1402` (4 subtests: sized masked guards, body-still-expands-incr ordering, local-width + nested tests, fail-closed forms); `--verify-hdl` (lint + yosys) clean on the flat and nested cases; `verilator --binary` sim → body runs iff the bit has the tested value (`bit3=1: hit=1,miss=0`; `bit3=0: hit=0,miss=1`); full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- A composable guard-expression predicate `(bit-set? reg N)` usable inside a
  larger `(& …)` guard — deferred (needs guard-expression rewriting and the same
  sized-literal handling; the statement form covers the common case).
- A dynamic (runtime) bit index.

## Acceptance Criteria

- `(when-bit …)` / `(unless-bit …)` lower to the documented masked `(when …)`,
  are verilator-lint + yosys clean, and simulate correctly (body runs iff the bit
  has the tested value); malformed forms and symbolic widths fail closed; a 13e/
  13d section + 13k row document them with a runnable example; `ISF_SPEC`
  registers the t/. Each leaf committed via `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created. Spiked the guard: an unsized `(& reg 8)` guard hits
  WIDTHEXPAND and a functional miss (multi-bit truthiness on a 32-bit
  intermediate); the width-qualified `(!= (& reg 8'h08) 8'h00)` form is clean and
  correct — hence the sized-literal masked design. Companion to `ISF-BIT-OPS`.
- `2026-06-02`: **shipped** — `_expand_bit_tests` desugar (sized masked `(when …)`,
  body-expanding, recursive); `t/1402` (4 subtests), 13e Branch-On-A-Bit section
  + 13k row, `ISF_SPEC` registers `t/1402`. The `flag_poll` example is
  verilator/yosys clean and simulates correctly. Tree closed.
