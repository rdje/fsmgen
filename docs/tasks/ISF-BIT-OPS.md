# ISF-BIT-OPS: `(set-bit NAME N)` / `(clear-bit NAME N)` / `(toggle-bit NAME N)`

## Metadata

- Tree ID: `ISF-BIT-OPS`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Single-bit register manipulation — the bread-and-butter of CSR / flag / control
register intent in chip design (set an enable bit, clear an interrupt flag,
toggle a mode). The follow-on construct named in `ISF-COMPOUND-ASSIGN`'s
non-goals.

```lisp
(set-bit    ctrl 0)   ;; ctrl[0] <- 1   (enable)
(clear-bit  irq  3)   ;; irq[3]  <- 0   (acknowledge / clear flag)
(toggle-bit mode 7)   ;; mode[7] <- ~mode[7]
```

## Ground truth

Pure ISF (IAL1) parser desugar into the existing `(set …)` data op, using only
supported `.fsm` operators (`|`, `&`, `^`) and **single-level** expressions
(verified verilator-lint + yosys clean; nested forms or `(<< 1 N)` create an
unsized 32-bit intermediate → WIDTHEXPAND/WIDTHTRUNC, and `~` is not a supported
operator):

```lisp
(set-bit    x N) -> (set x (| x <2^N>))
(toggle-bit x N) -> (set x (^ x <2^N>))
(clear-bit  x N) -> (set x (& x <INVMASK>))   ; INVMASK = (2^W - 1) ^ (2^N)
```

`N` is a literal bit index with `0 <= N < W`, where `W` is the register's
declared width. `set-bit` / `toggle-bit` masks (`2^N`) are width-independent;
`clear-bit`'s inverse mask requires the literal width `W`.

## Design

- A parser pass `_expand_bit_ops` runs in `_build_actor` (alongside / after
  `_expand_compound_assign`, so the emitted `(set …)` is final). It walks clause
  lists, recursing into control-flow bodies, and rewrites each
  `(set-bit|clear-bit|toggle-bit NAME N)` to the matching single-level `(set …)`.
- A register-width resolver looks `NAME` up among the transaction's `(local …)`,
  the actor interface ports, and `(storage (var …))` declarations, returning a
  literal width or undef.
- Validation (fail closed): a missing/non-scalar name; a non-literal or negative
  `N`; `N >= W`; and (for `clear-bit`, which needs the inverse mask) an
  unresolvable / non-literal (parameter/constant/symbolic) width.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `set-bit` + `toggle-bit` (width-independent `2^N` masks) + width
  validation (`N < W` when resolvable) + tests + docs. `done`.
- `.3` `clear-bit` (inverse-mask, requires literal width) + fail-closed on
  symbolic width + tests + docs. `done`.

`.2` and `.3` landed together — the shared register-width resolver
(`_bit_op_width_map`) made one pass cleaner than two.

## Implementation

- `Parser.pm`: `_expand_bit_ops` runs in `_build_actor` right after
  `_expand_compound_assign` (so the emitted `(set …)` is final and the actor
  interface / storage / locals it reads are populated). `_bit_op_width_map`
  builds a per-transaction `name -> literal width` map (locals → interface ports
  → storage vars; only a bare non-negative integer counts; a declared-but-
  symbolic width maps to undef). `_expand_bit_ops_in_list` /
  `_bit_op_rewrite_clause` walk and recurse into `when`/`while`/`until`/`repeat`/
  `switch` bodies. `_desugar_bit_op` emits the single-level masked `(set …)` and
  enforces the fail-closed rules.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2`/`.3` | `t/1401` (4 subtests: set/toggle masks, clear inverse-mask from interface/local/storage widths, control-flow recursion, fail-closed forms); `csr_ctl` doc example `--verify-hdl` (lint + yosys) clean and `verilator --binary` sim → `en=1, irq=247, mode=16`; full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- Dynamic (runtime) bit index — the mask would need a runtime shift, which is not
  single-level / width-clean. Literal index only for now.
- Multi-bit field set/clear (a possible later `(set-field …)` construct).
- Bit *test* in a condition (`(when (bit reg N) …)`) — a guard helper, separate.

## Acceptance Criteria

- The three ops lower to the documented single-level `(set …)`, are
  verilator-lint + yosys clean, and simulate correctly (set/clear/toggle a known
  bit); malformed forms and (for `clear-bit`) symbolic widths fail closed; a 13e
  section + 13k row document them with a runnable example; `ISF_SPEC` registers
  the t/. Each leaf committed via `COMMIT.md`.

## Blockers

- None. Depends on `CODEGEN-RESET-VALUE-HOLD` only for examples that initialise a
  register via a reset value and then bit-twiddle it across cycles (now fixed).

## Changelog

- `2026-06-02`: Created. Spiked the operator surface: single-level `(| r 2^N)`,
  `(& r INVMASK)`, `(^ r 2^N)` are lint+synth clean and simulate correctly;
  nested `(^ r (& r M))` and `(<< 1 N)` forms hit WIDTHEXPAND, and `~` is
  unsupported — hence the single-level masked design. Related:
  `ISF-COMPOUND-ASSIGN` (the sibling compound-assignment sugar).
- `2026-06-02`: **shipped** — `set-bit` / `clear-bit` / `toggle-bit` desugar in
  `_expand_bit_ops` with a shared width resolver; `t/1401` (4 subtests), 13e
  section + 13k row, `ISF_SPEC` registers `t/1401`. The `csr_ctl` example
  simulates to `en=1, irq=247, mode=16` and is verilator/yosys clean. Tree
  closed. (`set-bit`/`toggle-bit` masks `2^N` width-independent; `clear-bit`
  inverse mask needs a literal width, failing closed on symbolic widths.)
