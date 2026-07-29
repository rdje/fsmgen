---
id: ial2-post-exact-three-paired-composition-next-owner-selection
title: The exact-three paired AHB profile alias is the next bounded IAL2 owner
answers:
  - "what comes after generic exact-three paired AHB BUSY composition?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.817 select?"
  - "is the exact-three paired AHB alias next?"
  - "why is two-subordinate exact-three AHB not next?"
  - "does the post-exact-three selector activate HIAL and VIAL?"
  - "is Verilator a traditional event-driven simulator?"
  - "how does Verilator handle events and timing?"
  - "why does VIAL need a full-language UVM simulator profile?"
date: 2026-07-29
status: current
tags: [ial2, ahb, busy, exact-three, composition, profile-alias, selector, hial, vial, verilator, event-driven]
evidence: docs/IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t; t/1531-ial2-ahb-exact-three-paired-busy-composition.t; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; https://verilator.org/guide/latest/overview.html; https://verilator.org/guide/latest/languages.html; https://verilator.org/guide/latest/connecting.html
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.817|IAL2-FEATURE-COMPLETENESS-FRONTIER\.818|exact-three paired AHB profile alias|event-capable compiled simulation|portable-fast SystemVerilog|324 protocol|365 supported|48 AHB' docs/IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md docs/knowledge/ial2-post-exact-three-paired-composition-next-owner-selection.md
---

After generic one-subordinate exact-three paired AHB composition shipped at
323 protocol / 364 supported-smoke plus strict / 47 AHB paths, parent selector
`.817` selects `.818`, the byte-identical matching `.ahb` profile alias. A
repository-local same-volume candidate strict-checks without diagnostics,
keeps the exact 3 IAL1/4 IAL0 artifacts, three-child `ahb_tb`, exact-three
requester metadata, BUSY parking, one-hot response ownership, and normalized
semantic root, while existing suffix handling removes only alias-specific
residue. The future support-accounted boundary is 324/365/48 split 24/24, with
t1532 owning alias parity and t1531 retained as shared behavioral proof.

The selector keeps the SystemVerilog-backed IAL2 priority and rejects the
two-subordinate topology, wider counts, new BUSY policy/status/burst/signal
semantics, generic priority work, decision `0020`, and HIAL/VIAL activation as
larger or separately owned. HIAL/VIAL remains proposed with the agreed
simulator profiles intact.

Verilator is best described as event-capable compiled simulation, not a
traditional full-language event-driven simulator. Its model is explicitly
evaluated, and `--timing` adds supported delays, event controls, waits, forks,
and delayed-process scheduling. VIAL therefore uses Verilator for the fast
portable SystemVerilog subset profile and requires a separate
capability-qualified full-language/SystemVerilog-UVM profile; VHDL and
mixed-language claims remain separately qualified.
