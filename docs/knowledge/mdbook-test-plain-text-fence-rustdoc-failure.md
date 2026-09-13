---
id: mdbook-test-plain-text-fence-rustdoc-failure
title: mdBook text fences and repository-local render destinations
answers:
  - "why does mdbook test docs/book fail?"
  - "which mdBook fences used to be compiled as Rust?"
  - "does the AXI full-write slice break mdbook test?"
  - "does mdbook build still pass when mdbook test fails?"
  - "what repaired the plain-text diagram rustdoc failure?"
  - "what is mdbook --dest-dir relative to?"
  - "how should this repository select a disposable mdBook build directory?"
date: 2026-09-13
status: current
tags: [mdbook, rustdoc, documentation, validation, code-fence, pre-existing]
evidence: >-
  docs/book/src/13-intent-scheduling.md; docs/book/src/13b-transactions.md; docs/book/src/13f-composition.md; docs/book/src/13h-lowering-reference.md; docs/tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md;
  docs/audits/native-proxy-populated-controller-20260913/book-recovery.json; docs/audits/native-proxy-populated-controller-20260913/book-review.json; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: python3 -B docs/audits/native-proxy-populated-controller-20260913/audit.py --verify-saved
---

History: `8e0c5f1af948b928908005a7dcd6c73e3db5c152:docs/knowledge/mdbook-test-plain-text-fence-rustdoc-failure.md`.
Untyped plain-text fences sent diagrams to rustdoc as Rust. The historical repair
marked those fences `text`; its exact scope and original test result remain in Git.

From the repository root, use `mdbook build docs/book --dest-dir .artifacts/tmp/OWNED/book`.
The CLI destination is relative to the invocation directory; omit `../../../`.
The saved audit checks the mistaken render's exact copy, hash verification,
inspection and removal from both locations. It does not rebuild, repeat cleanup,
or reclassify the historical rustdoc test as a current full-book qualification.
