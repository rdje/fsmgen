# 0006 — Thorough mdBook with runnable examples

- Date: 2026-06-02 (migrated from harness-home memory)
- Type: convention
- Status: accepted

## Context

The mdBook (`docs/book/`) is the user-facing surface for FSMGen and must reflect
the codebase at all times. The user wants every feature documented thoroughly with
*lots* of runnable examples, trivial → realistic.

## Decision

- Every behaviour/syntax/diagnostic change ships **in the same slice** with mdBook
  updates: a dedicated section (e.g. `13e` data manipulation), the feature-matrix
  row (`13k`), and the focused-test registration (`docs/ISF_SPEC.md`).
- Examples must be **runnable and lowering-clean**: each book `(actor …)` block must
  lower under the book-example gate (`t/1376`), and realistic examples should be
  `--verify-hdl` clean and, where behaviour matters, `verilator --binary`-simulated.
- Paths in docs are repo-root-relative; no machine-local absolute paths (README
  "Documentation path invariant").

## Consequences

- `t/1376` (book-example lowering) grew 43 → 52 runnable fixtures across the
  theme-3 session; doc-truth gates (`t/1303`–`t/1307`, `t/1250`, `t/1305`) keep the
  book, matrix, and spec in sync with the code.
- A feature is not "done" until its mdBook section + matrix row + spec entry land
  and the doc gates pass.
