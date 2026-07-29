---
id: ial2-post-exact-four-paired-composition-next-owner-selection
title: Matching exact-four paired AHB profile alias is the next smallest owner
answers:
  - "what follows generic exact-four paired AHB shipment?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.824 select?"
  - "is the exact-four paired AHB profile alias selected?"
  - "what support identity is selected for the exact-four paired AHB alias?"
  - "what will t1538 prove?"
  - "why is two-window exact-four not selected first?"
  - "does selecting the exact-four paired alias activate HIAL or VIAL?"
date: 2026-07-30
status: current
tags: [ial2, ahb, exact-four, requester, subordinate, interconnect, busy, composition, profile-alias, selection, semantics, mcp]
evidence: docs/IAL2_POST_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; docs/IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif; t/1537-ial2-ahb-exact-four-paired-busy-composition.t; t/1532-ial2-ahb-exact-three-paired-busy-composition-profile-alias.t; perl/FSM/Adapter/IAL2/PPIF.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/16c-ial2-ahb.md
reverify: rg -n 't/1538|330|371|54 AHB|read_only=true|shell_access=false|two-subordinate' docs/IAL2_POST_EXACT_FOUR_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

Parent selector `.824` selected the matching byte-identical one-window
exact-four paired `.ahb` alias as implementation `.825`, activated only after
clean selector commit `5b601fffc` and now shipped. A 4,978-byte
repository-local candidate strict-checks with zero diagnostics, preserves
`ahb_tb`/top/3 children/28 signals, exact 3 IAL1/4 IAL0 artifacts, numeric
`before_beat=2`/`beats=4`, BUSY parking, and one-hot response ownership, and
passes normalized semantic export, real read-only shell-disabled MCP, and
public HDL verification with intentionally unmatched disposable support.

Selected support is
`intent.ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park`
with corresponding
`ial2_ahb_profile_alias_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli`
coverage, source kind `ial2_profile_alias`, supported-smoke plus strict,
`ahb_tb`/top/3-child expectations, and current 330/371/54 accounting split
27 `.ppif` / 27 `.ahb`.

t1538 owns alias parity without another simulation; t1537 remains the
sole assertion-enabled exact-four paired runtime. Two-window exact-four,
broader BUSY behavior, generic priority, HIAL/VIAL activation, verification
generation, VHDL, scale, and decision 0020 remain separate.

Clean `.825` behavior commit `40b8ead71` activates no-behavior selector `.826`
for the next exact decision.
