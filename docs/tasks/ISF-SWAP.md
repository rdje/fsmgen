# ISF-SWAP: `(swap A B)` exchange two registers

## Metadata

- Tree ID: `ISF-SWAP`
- Status: `done`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Exchange the contents of two registers — the `swap(a, b)` a high-level language
has (ping-pong buffers, sort steps, register renaming):

```lisp
(swap front back)   ;; front, back = back, front
```

## Ground truth

Pure ISF parser desugar into the classic temp-free XOR swap — three sequential
`(set …)`s, no scratch register, width-independent (works since the two writes to
`A` no longer alias, `CODEGEN-MULTI-EXPRESSION-SET-ALIAS`):

```lisp
(swap A B) -> (set A (^ A B))   ;; A = A^B
              (set B (^ A B))   ;; B = (A^B)^B = A0
              (set A (^ A B))   ;; A = (A^B)^A0 = B0
```

After the three states `A` holds the original `B` and `B` holds the original `A`.
`A` and `B` are distinct registers (XOR-swapping a register with itself would
zero it, so `A == B` fails closed).

## Design

- A parser pass `_expand_swap` runs in `_build_actor` alongside the other
  data-sugar passes (after cond/for/let/proc), walking clause lists and recursing
  into control-flow bodies. `_desugar_swap` validates `(swap A B)` and returns the
  three `(set …)`s.
- Fail closed: a missing / non-scalar `A` or `B`; `A == B`; extra operands.

## Slice plan

- `.1` select (this doc). `done`.
- `.2` `_expand_swap` desugar + tests + docs (13e section, 13k row). `done`.

## Verification

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-02` | `.2` | `t/1409` (3 subtests: three XOR sets with `A` the target of exactly two; nested in a control-flow body; fail-closed self-swap / one-operand / three-operand); `--verify-hdl` (lint + yosys) clean; `verilator --binary` sim → `p=77,q=200` exchange to `a=200,b=77`; full `prove t/`; `mdbook build`; `git diff --check` | `PASS` |

## Non-Goals

- Swapping more than two registers, or sub-fields — compose from pairwise swaps.

## Acceptance Criteria

- `(swap A B)` lowers to the three XOR `(set …)`s, is verilator-lint + yosys
  clean, and simulates correctly (`A` and `B` exchange); malformed forms / `A==B`
  fail closed; a 13e section + 13k row document it with a runnable example;
  `ISF_SPEC` registers the t/. Each leaf committed via `COMMIT.md`.

## Blockers

- None (depends on the landed `CODEGEN-MULTI-EXPRESSION-SET-ALIAS` so `A`'s two
  writes get distinct enables).

## Changelog

- `2026-06-02`: Created. Temp-free XOR swap, clean now that sequential writes to
  one register no longer alias — spiked `(set x (^ x y))(set y (^ x y))(set x (^
  x y))` and it exchanges `10`/`20` correctly, verilator/yosys clean.
- `2026-06-02`: **shipped** — `_expand_swap` desugar (three XOR sets); `t/1409`
  (3 subtests), 13e Exchange-Two-Registers section + 13k row, `ISF_SPEC`
  registers `t/1409`. verilator/yosys clean; sim exchanges `77`/`200`. Tree
  closed.
