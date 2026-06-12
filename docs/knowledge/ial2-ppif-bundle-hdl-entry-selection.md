---
id: ial2-ppif-bundle-hdl-entry-selection
title: IAL2 PPIF bundle HDL entry selection
answers:
  - "how should PPIF bundle HDL choose its entry?"
  - "can PPIF bundle HDL pick the first channel?"
  - "what is the PPIF bundle HDL wrapper contract?"
  - "what should PPIF bundle verify-hdl validate?"
date: 2026-06-12
status: current
tags: [ial2, ppif, bundle, hdl, selection]
evidence: docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md; docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-SELECTION.md; docs/tasks/IAL2-PPIF-BUNDLE-HDL-ENTRY-FIRST-SLICE.md
reverify: rg -n "aggregate wrapper/top|first channel wins|generated_artifacts.hdl_entry" docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md docs/book/src/14-feature-backlog.md
---

Default HDL generation for a multi-channel `.ppif` Valid-Ready bundle uses an
aggregate wrapper/top entry. It must not select the first generated channel
`.fsm` as the HDL root.

The selected contract keeps every channel monitor reviewable, adds an explicit
aggregate wrapper exposed through generated IAL1 and IAL0 review artifacts,
shares only identical clock/reset ports, fails closed on ambiguous port or
reset conflicts, and keeps full AXI manager behavior outside the first
HDL-entry implementation.
