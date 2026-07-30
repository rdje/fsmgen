---
id: ial2-post-public-sync-next-owner-selection
title: Four plain-text fence annotations follow completion of public-sync repair
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.837 select?"
  - "what follows the complete PUBLIC-SYNC-TEST-DRIFT-REPAIR tree?"
  - "why is the mdBook rustdoc fence repair selected now?"
  - "which four mdBook blocks still fail rustdoc?"
  - "does the post-public-sync selector activate the project-document lifecycle review?"
date: 2026-07-30
status: current
tags: [ial2, selector, mdbook, rustdoc, documentation, validation]
evidence: docs/IAL2_POST_PUBLIC_SYNC_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md; docs/knowledge/mdbook-test-plain-text-fence-rustdoc-failure.md; docs/book/src/13-intent-scheduling.md; docs/book/src/13b-transactions.md; docs/book/src/13f-composition.md; docs/book/src/13h-lowering-reference.md
reverify: mkdir -p .artifacts/tmp/mdbook-rustdoc-reverify && TMPDIR="$PWD/.artifacts/tmp/mdbook-rustdoc-reverify" mdbook test docs/book
---

Parent selector `.837` chooses proposed
`MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`. On clean activation commit
`9cacba136`, a full-book doctest run with an absolute repository-derived
`TMPDIR` fails only because these four plain-text blocks remain untyped:

- the Pipeline diagram in `13-intent-scheduling.md`;
- the transaction-to-state sketch in `13b-transactions.md`;
- the Composition Architecture diagram in `13f-composition.md`;
- the APB state summary in `13h-lowering-reference.md`.

The bounded child changes only those four opening fences to explicit `text`,
preserves their content, and requires both full-book doctest and HTML-build
success. The selector does not activate or edit the child.

The scheduled four-document lifecycle review stays proposed. Interim decision
`0025` remains controlling: update `CHANGES.md` every slice, update
`DEVELOPMENT_NOTES.md` only when useful rationale lacks a better durable home,
and leave `ROADMAP_STATUS.md` plus `LIVE_ACHIEVEMENT_STATUS.md` untouched.
Explicitly director-gated items remain inactive.

