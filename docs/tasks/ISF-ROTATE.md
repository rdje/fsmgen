# ISF-ROTATE: `(rotate-left REG [by N])` / `(rotate-right REG [by N])`

## Metadata

- Tree ID: `ISF-ROTATE`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Bit rotation — the wrap-around sibling of `shift_left` / `shift_right`, the
bread-and-butter of LFSRs, CRC, barrel shifters, and circular buffers:

```lisp
(rotate-left  lfsr)        ;; rotate lfsr left  by 1 (MSB -> LSB)
(rotate-right tag by 3)    ;; rotate tag  right by 3
```

## Ground truth

Pure ISF parser desugar into a single masked `(set …)` using the supported shift
and OR operators (shift *amounts* are plain literals — they do not 32-bit-expand
the result, unlike value-operand literals, so the form is verilator-lint + yosys
clean):

```lisp
(rotate-left  REG by N) -> (set REG (| (<< REG N) (>> REG (W-N))))
(rotate-right REG by N) -> (set REG (| (>> REG N) (<< REG (W-N))))
```

`N` defaults to `1` and is a literal with `0 < N < W`; `W` is the register's
declared literal width (resolved from a `(local …)`, an interface port, or a
`(storage (var …))`), needed for the `W-N` counter-shift amount.

## Design

- A parser pass `_expand_rotate` runs in `_build_actor` alongside the other
  data-sugar passes (after cond/for/let/proc), reusing `_bit_op_width_map`. It
  walks clause lists, recurses into control-flow bodies, and `_desugar_rotate`
  rewrites each `(rotate-left|rotate-right REG [by N])` to the masked `(set …)`.
- Fail closed: a missing / non-scalar `REG`; a malformed `by` (not `by` + a
  literal); a non-literal or out-of-range `N` (`N <= 0` or `N >= W`); a symbolic
  width.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_rotate` desugar + tests + docs (13e section, 13k row). `done`.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1408` (3 subtests: left/right desugar with `W-N` counter shift, width from a local, by-N, control-flow recursion; fail-closed out-of-range/malformed-by/symbolic-width); `--verify-hdl` (lint + yosys) clean; `verilator --binary` sim → `0x81 rol1 = 0x03`, `0x01 ror3 = 0x20`; full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- A runtime (signal) rotate amount — literal `N` only (the shift-back amount
  `W-N` must be a literal).
- Rotate of a field / sub-range (a possible later extension).

## Acceptance Criteria

- `(rotate-left/right REG [by N])` lowers to the documented masked `(set …)`, is
  verilator-lint + yosys clean, and simulates correctly (bits wrap around);
  malformed forms / out-of-range `N` / symbolic widths fail closed; a 13e section
  + 13k row document them with a runnable example; `ISF_SPEC` registers the t/.
  Each leaf committed via `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created. Spiked `(| (<< r 1) (>> r 7))` for an 8-bit register —
  verilator/yosys clean and rotates correctly (`0x81` rol 1 -> `0x03`). The
  wrap-around complement to the existing `shift_left` / `shift_right`.
- `2026-06-02`: **shipped** — `_expand_rotate` desugar (masked shift-OR, width
  resolved via `_bit_op_width_map`, optional `by N`); `t/1408` (3 subtests), 13e
  Bit Rotation section (with a runnable `spinner` example) + 13k row, `ISF_SPEC`
  registers `t/1408`. verilator/yosys clean; sim rotates correctly both
  directions. Tree closed.
