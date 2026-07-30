---
id: ial2-post-assertion-precedence-next-owner-selection
title: mdBook VHDL boundary sync follows assertion-precedence repair
answers:
  - "what follows the nested-bitwise assertion precedence repair?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.833 select?"
  - "why is the mdBook VHDL introduction sync selected next?"
  - "does FSMGen currently have any VHDL support?"
  - "does selecting the VHDL book sync activate HIAL or VIAL?"
date: 2026-07-30
status: current
tags: [ial2, selector, mdbook, vhdl, documentation, truth-sync]
evidence: docs/IAL2_POST_ASSERTION_PRECEDENCE_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.md; docs/book/src/00-introduction.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md; docs/book/src/14-feature-backlog.md; docs/knowledge/direct-vhdl-scaffold.md; docs/knowledge/direct-vhdl-reduction-expression-lowering-behavior.md; docs/decisions/0023-vhdl-generation-success-is-not-reduction-expression-validation.md
reverify: rg -n -i 'explicit VHDL support|VHDL: recognized|Composition has the same backend boundary|Status: partially shipped; full backend remains backlog' docs/book/src/00-introduction.md docs/book/src/10-errors-strict-mode-and-troubleshooting.md docs/book/src/14-feature-backlog.md
---

Parent selector `.833` selects proposed no-behavior leaf
`MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1` after the nested-bitwise concurrent-
assertion repair ships cleanly.

The book currently contradicts itself. Chapter 00 says explicit VHDL support
is not implemented, Chapter 10 describes VHDL and composition as unavailable,
and canonical Chapter 14 correctly documents a partially shipped direct and
bounded composition VHDL subset. The selected leaf aligns the two summaries
without claiming a full backend, external compiler qualification, GHDL,
general composition, record/array/package emission, or backend parity.

This is a book-only truth repair. It changes no parser, lowering, CLI,
generated HDL, report, support accounting, test, or runtime behavior.
HIAL/VIAL, end-to-end scale, other startup maintenance, known defects,
protocol/backend expansion, simulator profiles, and decision `0020` remain
independently proposed, deferred, or gated.

