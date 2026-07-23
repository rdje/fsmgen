---
id: mdbook-test-plain-text-fence-rustdoc-failure
title: Four untyped plain-text diagrams make mdbook test invoke rustdoc incorrectly
answers:
  - "why does mdbook test docs/book fail?"
  - "which mdBook fences are being compiled as Rust?"
  - "does the AXI full-write slice break mdbook test?"
  - "does mdbook build still pass when mdbook test fails?"
  - "what owns the plain-text diagram fence repair?"
date: 2026-07-23
status: current
tags: [mdbook, rustdoc, documentation, validation, code-fence, pre-existing]
evidence: docs/book/src/13-intent-scheduling.md; docs/book/src/13b-transactions.md; docs/book/src/13f-composition.md; docs/book/src/13h-lowering-reference.md; docs/tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md
reverify: mdbook test docs/book
---

`mdbook test docs/book` currently fails because four pre-existing plain-text
diagrams use untyped triple-backtick fences. mdBook passes those fences to
rustdoc as Rust, which rejects their Unicode arrows and Lisp-like pseudocode.
The affected diagrams are the Pipeline block in `13-intent-scheduling.md`, the
transaction-to-state sketch in `13b-transactions.md`, the composition
architecture block in `13f-composition.md`, and the APB state summary in
`13h-lowering-reference.md`.

Git blame dates the affected fences to 2026-05-12 through 2026-05-14. The
failure therefore predates and is unrelated to the 2026-07-23 AXI full-write
composition slice that exposed it. `mdbook build docs/book` still passes and
renders the book; the defect is specifically the doctest classification.

Proposed task `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1` owns the bounded repair:
change only those four opening fences to explicit `text`, preserve diagram
content, and require both `mdbook test` and `mdbook build` plus doctrine gates.
