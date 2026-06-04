---
id: isf-verification-book-map
title: Where the ISF verification/property surface is documented in the book
answers:
  - "where is the ISF verification / assert / assume / cover surface documented?"
  - "which book chapter covers ISF temporal properties, trigger anchors, monitors?"
  - "where do I document a new ISF property construct / did the book get synced?"
  - "which mdBook chapters do I update when I add an ISF verification feature?"
date: 2026-06-04
status: current
tags: [isf, verification, docs, mdbook, doc-map]
evidence: docs/book/src/13d-control-flow.md; docs/book/src/13k-isf-feature-support-matrix.md; t/1376-isf-book-example-lowering-audit.t; t/1305-isf-book-feature-matrix-audit.t
reverify: grep -rln "assert\|monitor\|=>\|sampled-value" docs/book/src/13d-control-flow.md docs/book/src/13k-isf-feature-support-matrix.md
---

The ISF verification/property surface (`assert`/`assume`/`cover`, implication `=>`,
`next`/`within`, trigger anchors `after`/`point`/`at`/`on-as`, the `(monitor (within
S N))` bounded-eventually, and the sampled-value predicates `stable`/`changed`/`rose`/
`fell`) is documented in **exactly two** book chapters — update both when adding a
verification feature:

- **`13d-control-flow.md`** — the **canonical** surface: each construct with runnable
  `(assert …)` examples (gated by `t/1376`, which lowers every complete `(actor …)`).
- **`13k-isf-feature-support-matrix.md`** — row "Immediate verification checks"
  (and "Temporal contracts" for the monitor): the Form + Behavior support-matrix entry
  (audited by `t/1305`).

Chapters that **only** mention the `(monitor (within …))` form and document its
arm/age/fail *hardware* lowering — **not** the property-leaf grammar, so a pure-SVA
leaf (e.g. sampled-value) needs **no** edit there: `13h-lowering-reference.md`
(Bounded-Eventually Monitors), `13-intent-scheduling.md`, `14-feature-backlog.md`.
Also register a new test in the `ISF_SPEC.md` focused-test index. The grammar's code
home is [[isf-property-grammar-location]]; the lowering pipeline is
[[isf-lowering-pipeline]].
