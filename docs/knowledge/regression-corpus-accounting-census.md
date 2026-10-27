---
id: regression-corpus-accounting-census
title: Regression catalog accounting is a focused structural check
answers:
  - "which focused check covers regression catalog membership and pinned totals?"
  - "how were stale catalog totals repaired during scalar-header delivery?"
date: 2026-10-27
status: current
tags: [regression, corpus, checks, evidence]
evidence: t/248-regression-corpus-accounting.t; perl/FSM/Support/RegressionCorpus.pm; docs/tasks/ISF-REDUCTION-DELIVERY.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
---

T248 checks named contracts, identifiers, classifications, paths, metadata and
pinned catalog totals. It does not execute every source fixture. It is directly
affected by catalog edits; complete source/runtime qualification is a separate
gate. Derive current rows through `regression_corpus_entries()` and independently
enumerate literal declaration records before updating a stale total.

The scalar-header audit retains the exact assertion epochs, committed baseline,
current API rows and independent literal census. Exact membership differences
attribute the stale totals to earlier admitted contracts and the new header
fixture; protocol and legacy counts remain unchanged. The owning leaf is
`ISF-REDUCTION-DELIVERY.3.2.3.2`. Tests watch the refreshed totals; this card
does not copy them as current state.
