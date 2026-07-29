---
id: ial2-post-two-subordinate-exact-three-paired-composition-next-owner-selection
title: The two-subordinate exact-three paired AHB alias is the next bounded IAL2 owner
answers:
  - "what follows generic two-subordinate exact-three paired AHB composition?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.820 select?"
  - "is the two-subordinate exact-three paired AHB alias next?"
  - "what path will the two-subordinate exact-three paired AHB alias use?"
  - "what support identity will own the two-subordinate exact-three alias?"
  - "does the post-two-window exact-three selector activate HIAL and VIAL?"
  - "will the two-window exact-three alias need a second runtime?"
date: 2026-07-29
status: current
tags: [ial2, ahb, busy, exact-three, two-subordinate, composition, profile-alias, selector, hial, vial, verilator]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t; t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.820|IAL2-FEATURE-COMPLETENESS-FRONTIER\.821|326 protocol|367 supported|50 AHB|t/1534|event-capable compiled simulation' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After generic two-subordinate exact-three paired AHB composition shipped at
325 protocol / 366 supported-smoke plus strict / 49 AHB paths, parent selector
`.820` selects `.821`, the byte-identical matching `.ahb` profile alias. A
repository-local same-volume candidate strict-checks at four-child `ahb_tb` / 29
signals with intentionally unmatched support, preserves exact 4 IAL1/5 IAL0
artifacts, requester `before_beat=2` / `beats=3`, both BUSY-parking contexts,
one-hot response ownership, normalized semantic root `top`, real read-only MCP,
and public `--verify-hdl`.

The selected support ID is
`intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`.
Implementation `.821` now ships at 326/367/50 split 25 `.ppif`/25 `.ahb`;
focused t1534 proves alias parity while t1533 remains the sole assertion-enabled
runtime. Proposed `.822` owns the next selection after the clean behavior
commit.

Counts above three, new BUSY policy/status/burst/signal semantics, generic
priority, decision `0020`, and HIAL/VIAL activation remain separate. HIAL/VIAL
retains portable-fast event-capable compiled Verilator versus a separately
qualified full-language/SystemVerilog-UVM simulator, with independent VHDL and
mixed-language profiles.
