# ISF-SET-FIELD: `(set-field NAME (bits HI LO) VALUE)`

## Metadata

- Tree ID: `ISF-SET-FIELD`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Write a named multi-bit field of a register to a value — the multi-bit
generalisation of `set-bit`, and the everyday way CSR fields are programmed (a
mode field, a divider ratio, a priority level):

```lisp
(set-field ctrl (bits 5 3) 5)   ;; ctrl[5:3] <- 3'b101, other bits preserved
(set-field div  (bits 7 0) 24)  ;; div[7:0]  <- 24
```

## Ground truth

Pure ISF parser desugar into a single (nested but width-clean) read-modify-write
`(set …)` using sized literals (the spike showed sized literals keep the nested
`(| (& …) …)` verilator-lint + yosys clean, where unsized literals 32-bit-expand):

```lisp
(set-field x (bits HI LO) V) ->
  (set x (| (& x W'dCLEARMASK) W'dSHIFTED))
    CLEARMASK = (2^W - 1) ^ (((2^(HI-LO+1)) - 1) << LO)   ; field bits zeroed
    SHIFTED   = V << LO                                    ; V placed in the field
```

`HI`, `LO`, and `V` are literals with `HI >= LO`, `HI < W`, and `V` fitting the
field (`V < 2^(HI-LO+1)`). `W` is the register's declared literal width (resolved
from a `(local …)`, an interface port, or a `(storage (var …))`), required for
the sized literals.

## Design

- A parser pass `_expand_set_fields` runs in `_build_actor` alongside the other
  data-sugar passes (after cond/for/let/proc), reusing `_bit_op_width_map`. It
  walks clause lists, recurses into control-flow bodies, and rewrites each
  `(set-field …)` to the masked read-modify-write `(set …)`.
- Fail closed: a missing name; a malformed `(bits HI LO)` sub-form; non-literal
  `HI`/`LO`/`V`; `HI < LO`; `HI >= W`; `V` overflowing the field; a symbolic
  width.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_set_fields` desugar + tests + docs (13e section, 13k row). `done`.

## Implementation

- `Parser.pm`: `_expand_set_fields` runs in `_build_actor` after `_expand_bit_ops`
  (a leaf statement, so ordering only matters for recursion — it walks and
  recurses into when/while/until/repeat/switch bodies, catching a `(set-field …)`
  inside a `when-bit`-produced `(when …)`). It reuses `_bit_op_width_map`.
  `_desugar_set_field` validates the `(bits HI LO)` selector, the literal value,
  the width, the range, and field overflow, then emits
  `(set NAME (| (& NAME W'dCLEARMASK) W'dSHIFTED))`.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1403` (3 subtests: sized masked RMW for multi-bit/single-bit/full-width fields; width from local/storage + control-flow recursion; fail-closed overflow/reversed/oor/missing-selector/symbolic-width); `--verify-hdl` (lint + yosys) clean; `verilator --binary` sim → `mode_set` `ctrl == 0xEF` (field set, other bits preserved); full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- A runtime (signal / expression) field value — the shift + mask would need
  runtime width care; literal field values only for now (the common CSR case).
- Reading a field (`get-field`) into a destination — a possible companion.
- Overlapping the one-expression-write-per-register limit: a `(set-field …)` is
  one expression `(set …)`, so two field writes to the same register in one
  transaction alias (documented; combine or use one per register).

## Acceptance Criteria

- `(set-field NAME (bits HI LO) V)` lowers to the documented masked `(set …)`,
  is verilator-lint + yosys clean, and simulates correctly (the field takes `V`,
  other bits preserved); malformed forms / overflow / symbolic widths fail
  closed; a 13e section + 13k row document it with a runnable example; `ISF_SPEC`
  registers the t/. Each leaf committed via `COMMIT.md`.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created. Spiked the read-modify-write: `(| (& r 8'hC7) 8'h28)`
  with sized literals is verilator/yosys clean and simulates correctly
  (`r: 0xFF -> 0xEF` for `[5:3] <- 5`), where the earlier unsized nested form
  hit WIDTHEXPAND — hence the sized-literal masked design. Generalises
  `ISF-BIT-OPS`' `set-bit`.
- `2026-06-02`: **shipped** — `_expand_set_fields` desugar; `t/1403` (3 subtests),
  13e Multi-Bit Field Write section + 13k row, `ISF_SPEC` registers `t/1403`. The
  `mode_set` example is verilator/yosys clean and simulates to `ctrl == 0xEF`.
  Tree closed.
