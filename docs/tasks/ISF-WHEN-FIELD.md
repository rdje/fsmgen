# ISF-WHEN-FIELD: `(when-field NAME (bits HI LO) VALUE body…)` / `(unless-field …)`

## Metadata

- Tree ID: `ISF-WHEN-FIELD`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Branch on a multi-bit register field value — the read/compare companion to
`set-field` (write), and the multi-bit generalisation of `when-bit`:

```lisp
(when-field   mode (bits 2 0) 3  (enter-turbo))   ;; run body when mode[2:0] == 3
(unless-field mode (bits 2 0) 3  (enter-normal))  ;; run body when mode[2:0] != 3
```

## Ground truth

Pure ISF parser desugar into a `(when …)` with a width-qualified masked
comparison (sized literals keep it lint-clean, as in `ISF-BIT-TEST`):

```lisp
(when-field   x (bits HI LO) V body…) -> (when (== (& x W'dFIELDMASK) W'dSHIFTED) body…)
(unless-field x (bits HI LO) V body…) -> (when (!= (& x W'dFIELDMASK) W'dSHIFTED) body…)
  FIELDMASK = ((2^(HI-LO+1)) - 1) << LO    ; the field's bit positions
  SHIFTED   = V << LO                       ; V placed in the field
```

`HI`, `LO`, `V` are literals (`HI >= LO`, `HI < W`, `V` fits the field); `W` is
the register's declared literal width (resolved from a `(local …)`, an interface
port, or a `(storage (var …))`), required for the sized literals.

## Design

- A parser pass `_expand_when_fields` runs in `_build_actor` **before**
  `_expand_compound_assign` / bit-op / set-field passes (like `_expand_bit_tests`)
  so those passes' `(when …)` recursion reaches sugar inside a desugared body. It
  reuses `_bit_op_width_map`, recurses into control-flow bodies and into its own
  `when-field`/`unless-field` bodies (nested), and expands its body before
  wrapping.
- Fail closed: a missing name; a malformed `(bits HI LO)`; non-literal
  `HI`/`LO`/`V`; `HI < LO`; `HI >= W`; `V` overflowing the field; an empty body;
  a symbolic width.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_when_fields` desugar + tests + docs (13e section, 13k row). `done`.

## Implementation

- `Parser.pm`: `_expand_when_fields` runs in `_build_actor` after `_expand_bit_tests`
  and before the compound/bit-op/set-field passes (so their `(when …)` recursion
  reaches body sugar). It reuses `_bit_op_width_map`, recurses into control-flow
  bodies, and `_desugar_when_field` validates the `(bits HI LO)` selector / literal
  value / width / range / field overflow / non-empty body, expands its own body
  (nested field tests), then wraps it in
  `(when (CMP (& NAME W'dFIELDMASK) W'dSHIFTED) body…)` (`==` for `when-field`,
  `!=` for `unless-field`).

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1404` (3 subtests: sized masked field comparisons low/high; body-still-expands-incr + local width; fail-closed overflow/empty-body/missing-selector/symbolic-width); `--verify-hdl` (lint + yosys) clean; `verilator --binary` sim → body runs iff the field compares as specified, upper bits masked off (`mode[2:0]==3` taken even with `mode=0xF3`); full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- Comparators other than `==` / `!=` on a field (`<`, `>` … ) — a possible later
  extension; equality covers the common mode/level dispatch.
- A runtime `VALUE`.

## Acceptance Criteria

- `(when-field …)` / `(unless-field …)` lower to the documented masked `(when …)`,
  are verilator-lint + yosys clean, and simulate correctly (body runs iff the
  field compares as specified); malformed forms / overflow / symbolic widths fail
  closed; a 13e section + 13k row document them with a runnable example;
  `ISF_SPEC` registers the t/. Each leaf committed via `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created. Completes the field story (`set-field` writes;
  `when-field` reads/compares) and generalises `ISF-BIT-TEST`'s `when-bit` to a
  multi-bit field. Same sized-literal masked design (`ISF-BIT-TEST` spike showed
  the unsized form is lint-dirty / mis-evaluates).
- `2026-06-02`: **shipped** — `_expand_when_fields` desugar; `t/1404` (3 subtests),
  13e Branch-On-A-Field section + 13k row, `ISF_SPEC` registers `t/1404`. The
  `mode_dispatch` example is verilator/yosys clean and simulates correctly. Tree
  closed.
