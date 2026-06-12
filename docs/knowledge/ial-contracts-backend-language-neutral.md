---
id: ial-contracts-backend-language-neutral
title: IAL contracts and mdBook are backend-language-neutral
answers:
  - "are IAL0 IAL1 IAL2 Perl-only APIs?"
  - "should the mdBook be backend language agnostic?"
  - "can FSMGen have Rust and JavaScript implementations?"
  - "should a JavaScript FSMGen run in the browser?"
  - "can a Rust FSMGen target Wasm?"
  - "can FSMGen have a Dart backend?"
  - "can Dart be a web target for FSMGen?"
date: 2026-06-12
status: current
tags: [architecture, ial0, ial1, ial2, mdbook, rust, wasm, javascript, dart, browser]
evidence: docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'backend-language-neutral|Rust/Wasm|browser-capable JavaScript|Dart/web|Perl 5|reference implementation|host abstractions' docs/decisions/0018-ial-contracts-are-backend-language-neutral.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

IAL0, IAL1, IAL2, and the mdBook are backend-language-neutral contracts, not
Perl-only APIs. FSMGen is currently implemented in Perl 5, and that
implementation is the reference/oracle while future implementations grow.

Future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web work should
implement the same public source syntax, generated review artifacts, reports,
diagnostics, and HDL behavior. Portable IAL contracts should not depend on
POSIX filesystem access, process spawning, Perl module loading, or other
host-only runtime details.
