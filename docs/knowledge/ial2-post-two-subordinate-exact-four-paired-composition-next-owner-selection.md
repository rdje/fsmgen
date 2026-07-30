---
id: ial2-post-two-subordinate-exact-four-paired-composition-next-owner-selection
title: The two-subordinate exact-four paired AHB alias is the next bounded IAL2 owner
answers:
  - "what follows generic two-subordinate exact-four paired AHB composition?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.827 select?"
  - "is the two-subordinate exact-four paired AHB alias next?"
  - "what path will the two-subordinate exact-four paired AHB alias use?"
  - "what support identity will own the two-subordinate exact-four alias?"
  - "does the post-two-window exact-four selector activate HIAL and VIAL?"
  - "will the two-window exact-four alias need a second runtime?"
  - "did IAL2-FEATURE-COMPLETENESS-FRONTIER.828 ship the selected alias?"
date: 2026-07-30
status: current
tags: [ial2, ahb, busy, exact-four, two-subordinate, composition, profile-alias, selector, hial, vial, verilator]
evidence: docs/IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ahb; t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t; t/1538-ial2-ahb-exact-four-paired-busy-composition-profile-alias.t; t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t; t/1540-ial2-ahb-two-subordinate-exact-four-paired-busy-composition-profile-alias.t; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.827|IAL2-FEATURE-COMPLETENESS-FRONTIER\.828|332 protocol|373 supported|56 AHB|t/1540|event-capable compiled' docs/IAL2_POST_TWO_SUBORDINATE_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After generic two-subordinate exact-four paired AHB composition shipped at
331 protocol / 372 supported-smoke plus strict / 55 AHB paths, parent selector
`.827` selected `.828`, the byte-identical matching `.ahb` profile alias.

A repository-local same-volume 6,645-byte candidate strict-checks at four-child
`ahb_tb` / 29 signals with intentionally unmatched support, preserves exact
4 IAL1/5 IAL0 payload parity, width-three `4 -> 3 -> 2 -> 1 -> 0`, two windows,
both BUSY-parking contexts, one-hot response ownership, normalized semantic
root `top`, real repo-relative read-only shell-disabled MCP, and public
`--verify-hdl`. Existing suffix handling removes only three profile-alias
residue IDs and alias-exposure wording. The exact 11-file/2,180,377-byte probe
workspace was removed without residue.

The selected support ID is
`intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park`.
Completed `.828` reaches 332/373/56 split 28 `.ppif`/28 `.ahb`. t1540 passes
4 top-level subtests and 97 nested assertions for exact alias parity without a
second simulation, while t1539 remains the sole assertion-enabled runtime.

Counts above four, new BUSY policy/status/burst/signal semantics, generic
priority, decision `0020`, HIAL/VIAL activation, verification generation,
VHDL, portability, scale, and other protocol/backend work remain separate.
HIAL/VIAL retains portable-fast event-capable compiled Verilator versus a
separately qualified full-language/SystemVerilog-UVM simulator, with independent
VHDL and mixed-language profiles.

Clean selector commit `bc29c2e49` activates only `.828`; the alias remains
absent and public behavior stays at 331/372/55 during activation.
