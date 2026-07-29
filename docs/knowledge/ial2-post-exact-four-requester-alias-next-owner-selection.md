---
id: ial2-post-exact-four-requester-alias-next-owner-selection
title: One-window exact-four paired AHB readiness follows the completed exact-four requester pair
answers:
  - "what follows the exact-four AHB requester alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.823 select?"
  - "is exact-four paired AHB BUSY composition next?"
  - "why select one-window exact-four pairing before two-window pairing?"
  - "does the exact-four paired feasibility probe lower cleanly?"
  - "does the post-exact-four selector activate HIAL and VIAL?"
  - "is Verilator treated as a full SystemVerilog UVM simulator?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-four, composition, selector, hial, vial, verilator]
evidence: docs/IAL2_POST_EXACT_FOUR_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md; docs/IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_requester_busy_insert_four.ppif; ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.823|EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT|1,247,052|329 protocol|event-capable compiled' docs/IAL2_POST_EXACT_FOUR_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md
---

After exact-four requester generic/profile shipment reached 328/369/52 split
26/26, parent selector `.823` chose proposed one-window exact-four paired BUSY
composition readiness as the smallest adjacent roadmap owner.

A same-volume transform of the shipped exact-three paired source strict-checks
with zero diagnostics, lowers to exact 3 IAL1 / 4 IAL0 artifacts under
`ahb_tb`, preserves width-three literal-four requester state, one-hot response
ownership, BUSY parking, normalized semantic root `top`, and passes public
`--verify-hdl`. Support is correctly unmatched. The exact 9-file / 1,247,052-
byte workspace was removed without residue.

The selected audit must still prove assertion-enabled 5 presentations / 4
beats / 1 BUSY episode / 4 qualified BUSY events / 1 resumed `SEQ` / storage
`0x44332211` plus semantic/read-only-MCP parity before a public contract.
Two-window exact-four, counts above four, new policies/status/bursts/signals,
HIAL/VIAL activation, scale, VHDL, verification generation, and decision 0020
remain separate. Verilator remains the portable-fast event-capable compiled
profile, not the full-language/SystemVerilog-UVM authority.

Clean selector commit `d91c5c7c9` now activates only readiness audit `.1`;
the public 328/369/52 boundary remains unchanged during activation.

Completed `.1` now proves assertion-enabled exact-four paired readiness plus
real read-only MCP and selects pending generic contract `.2`; no source ships.
