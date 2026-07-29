---
id: ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias-behavior
title: Two-subordinate exact-three paired AHB BUSY ships through a byte-identical .ahb alias
answers:
  - "does the two-subordinate exact-three paired AHB BUSY .ahb alias ship?"
  - "what is ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb?"
  - "is the two-subordinate exact-three AHB alias a separate generator?"
  - "what support id owns the two-subordinate exact-three .ahb alias?"
  - "can MCP semantically introspect the two-subordinate exact-three AHB alias?"
  - "how many AHB IAL2 paths ship after the two-subordinate exact-three alias?"
  - "which test proves the two-subordinate exact-three alias?"
date: 2026-07-29
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-three, two-subordinate, profile-alias, semantics, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t; t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: cmp ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb && scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- prove -v t/1534-ial2-ahb-two-subordinate-exact-three-paired-busy-composition-profile-alias.t
---

The matching `.ahb` alias ships as a byte-identical view of the generic
two-subordinate exact-three paired BUSY source. Both use the existing
requester/status/control/interconnect architecture through IAL2 -> IAL1 ->
IAL0 -> HDL; the alias is source data, not another generator.

The alias preserves numeric requester-child `busy_insertion.beats=3`, width-two
`3 -> 2 -> 1 -> 0`, both child/propagated `parks_on=[busy]`, status `[0,4)` and
control `[4,8)` windows, one-hot retained response ownership, module `ahb_tb`,
four children, 29 signals, and semantic root `top`. Existing suffix handling
removes only alias-specific residue.

Its support ID is
`intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`.
Focused t1534 proves byte/report/strict/schedule/semantic/read-only-MCP/artifact/
verifier/diagnostic/preservation parity without a second runtime; t1533 remains
the shared assertion-enabled 10/8/2/6/2 behavioral proof.

This alias established 326/367/50. The generic exact-four requester established
327/368/51 and its matching alias established 328/369/52. The later generic
exact-four paired source moves current accounting to 329 protocol / 370
supported+strict / 53 AHB paths split 27 `.ppif` / 26 `.ahb`. Every
support-accounted semantic feature continues to
extend one normalized semantic surface and preserve read-only MCP parity.
