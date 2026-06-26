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
  - "what task owns backend-language portability?"
  - "what is the next backend-language portability frontier?"
  - "must every FSMGen variant satisfy the same contracts?"
  - "what role does Perl play for future FSMGen variants?"
  - "should the book be enough to implement FSMGen in another language?"
  - "should FSMGen depend on sv2v for Verilog conversion?"
  - "can sv2v be used for FSMGen SystemVerilog to Verilog conversion?"
date: 2026-06-26
status: current
tags: [architecture, ial0, ial1, ial2, mdbook, rust, wasm, javascript, dart, browser, verilog]
evidence: docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md; docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md; docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/knowledge/backend-language-portability-readiness-audit.md; docs/knowledge/backend-language-portable-in-memory-api-selection.md
reverify: rg -n 'backend-language-neutral|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER|BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT|BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION|Rust/Wasm|browser-capable JavaScript|Dart/web|Julia|Perl 5|reference implementation|Perl reference|FSMGen.*public contracts|in-memory host APIs|language-X|sv2v|SystemVerilog-to-Verilog|external converter|portable in-memory API contract|request/result|virtual artifacts|BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4' docs/decisions/0018-ial-contracts-are-backend-language-neutral.md docs/tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/knowledge/ial-contracts-backend-language-neutral.md docs/knowledge/backend-language-portability-readiness-audit.md docs/knowledge/backend-language-portable-in-memory-api-selection.md
---

IAL0, IAL1, IAL2, and the mdBook are backend-language-neutral contracts, not
Perl-only APIs. FSMGen is currently implemented in Perl 5, and that
implementation is the reference/oracle while future implementations grow.

Future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web work should
implement the same public source syntax, generated review artifacts, reports,
diagnostics, and HDL behavior. Portable IAL contracts should not depend on
POSIX filesystem access, process spawning, Perl module loading, or other
host-only runtime details.

Every future FSMGen variant or implementation must satisfy the same FSMGen
public contracts. The portability target is identical in-memory behavior on
any suitable platform/environment, with feature, functionality, diagnostic,
semantic-introspection, example, fixture, and test parity against the Perl
reference/oracle.

`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER` now owns the portability
contract/infrastructure roadmap. `.1` created the tree, `.2.1` captured the
variant-parity doctrine, and `.2.2` completed the readiness audit for public
contracts, semantic introspection/MCP surfaces, support accounting, fixture
parity, host abstractions, Perl-oracle parity gates, and mdBook language-X
blueprint gaps. `.2.3` drafted the portable in-memory request/result API
candidate with JSON-safe envelopes and virtual artifacts, but remains blocked
on focused corpus verification. `.2.4`, the host source/artifact abstraction
selector, remains pending until `.2.3` completes. No Rust/Rust-Wasm, browser
JavaScript, Dart/web, Julia, or other non-Perl implementation work may change
code or public contracts before those selectors complete.

For SystemVerilog-to-Verilog portability, FSMGen-owned generation/lowering is
the default. External converters such as `sv2v` are not selected dependencies
by default; they are future audit candidates only, usable as optional
validation aids or selected dependencies only if a later owned audit proves
exceptional quality and coverage.
