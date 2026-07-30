---
id: mdbook-test-plain-text-fence-rustdoc-failure
title: Four explicit text annotations keep plain-text diagrams out of rustdoc
answers:
  - "why does mdbook test docs/book fail?"
  - "which mdBook fences used to be compiled as Rust?"
  - "does the AXI full-write slice break mdbook test?"
  - "does mdbook build still pass when mdbook test fails?"
  - "what repaired the plain-text diagram rustdoc failure?"
date: 2026-07-23
status: current
tags: [mdbook, rustdoc, documentation, validation, code-fence, pre-existing]
evidence: docs/book/src/13-intent-scheduling.md; docs/book/src/13b-transactions.md; docs/book/src/13f-composition.md; docs/book/src/13h-lowering-reference.md; docs/tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md
reverify: scratch=.artifacts/tmp/mdbook-rustdoc-reverify; trap 'rm -rf "$scratch"' EXIT; mkdir -p "$scratch"; TMPDIR="$PWD/$scratch" mdbook test docs/book
---

`mdbook test docs/book` used to fail because four pre-existing plain-text
diagrams had untyped triple-backtick fences. mdBook passed those fences to
rustdoc as Rust, which rejected their Unicode arrows and Lisp-like pseudocode.
Completed `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1` now classifies exactly the
Pipeline block in `13-intent-scheduling.md`, transaction-to-state sketch in
`13b-transactions.md`, composition architecture block in `13f-composition.md`,
and APB state summary in `13h-lowering-reference.md` as `text`.

Git blame dates the affected fences to 2026-05-12 through 2026-05-14. The
failure therefore predated and was unrelated to the 2026-07-23 AXI full-write
composition slice that exposed it.

The implementation changes only those four opening markers: git reports one
insertion/one deletion per book file, while zero-context diff contains no
diagram, prose, or example-content edit. Full `mdbook test docs/book` now exits
zero across all 36 chapters, and `mdbook build docs/book` remains clean.
