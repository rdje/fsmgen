---
id: ial2-protocol-platform-intent-mdbook-chapter
title: IAL2 protocol/platform intent mdBook chapter scaffold
answers:
  - "where is the IAL2 protocol and platform intent mdBook chapter?"
  - "is IAL2 one language or a separate dialect for each protocol?"
  - "what do IAL2 protocol profiles change?"
  - "what are the IAL2 guided more-control and raw/full-control documentation modes?"
  - "does IAL2 bypass generated ISF and FSM review artifacts?"
  - "what is the current AHB boundary in the IAL2 mdBook chapter?"
date: 2026-08-09
status: current
tags: [ial2, mdbook, protocol-intent, ppif, axi, apb, ahb, documentation]
evidence: docs/book/src/16-ial2-protocol-platform-intent.md; docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md
reverify: rg -n 'one IAL2 language layer|protocol-specific vocabulary|IAL2 source -> generated IAL1 \.isf -> generated IAL0 \.fsm -> HDL|aliases over the same IAL2 model' docs/book/src/16-ial2-protocol-platform-intent.md
---

`docs/book/src/16-ial2-protocol-platform-intent.md` is the user-facing IAL2 map.

Its guided, more-control, and raw/full-control modes all preserve generated
IAL1 `.isf` and IAL0 `.fsm` review artifacts before HDL.

IAL2 is one language layer, not one dialect or lowering path per protocol.
The `.ppif` `(profile ...)` exposes protocol-specific vocabulary; selected
`.axi`, `.apb`, and `.ahb` suffixes are aliases. All profiles share source,
diagnostic, report, accounting, and `IAL2 -> IAL1 -> IAL0 -> HDL` contracts.
AXI, APB, and AHB remain shipped but bounded surfaces, not full protocols.
