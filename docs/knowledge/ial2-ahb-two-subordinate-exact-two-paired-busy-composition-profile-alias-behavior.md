---
id: ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias-behavior
title: Two-subordinate exact-two paired AHB BUSY ships through a byte-identical .ahb alias
answers:
  - "does the two-subordinate exact-two paired AHB BUSY .ahb alias ship?"
  - "what is ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb?"
  - "is the two-subordinate exact-two AHB alias a separate generator?"
  - "what support id owns the two-subordinate exact-two .ahb alias?"
  - "can MCP semantically introspect the two-subordinate exact-two AHB alias?"
  - "how many AHB IAL2 paths ship after the two-subordinate exact-two alias?"
  - "which test proves the two-subordinate exact-two alias?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, two-subordinate, profile-alias, semantics, mcp]
evidence: docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1525-ial2-ahb-two-subordinate-exact-two-paired-busy-composition.t; t/1526-ial2-ahb-two-subordinate-exact-two-paired-busy-composition-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: cmp ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
---

The matching `.ahb` alias ships as a byte-identical view of the generic
two-subordinate exact-two paired BUSY source. Both use the existing four-child
requester/status/control/interconnect architecture through
IAL2 -> IAL1 -> IAL0 -> HDL; the alias is source data, not another generator.

The alias preserves numeric requester-child `busy_insertion.beats=2`, both
subordinate and propagated `parks_on=[busy]` policies, status `[0,4)` and
control `[4,8)` windows, one-hot retained response ownership, module `ahb_tb`,
four children, and semantic root `top`. Existing suffix handling removes only
alias-specific residue.

Its support ID is
`intent.ahb_profile_alias_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park`
and source kind is `ial2_profile_alias`. Focused t/1526 proves strict check,
schedule, normalized semantic JSON, real read-only MCP, exact artifact,
verifier, diagnostic, and preservation parity without a second runtime. t/1525
remains the shared two-window generated-HDL runtime proof.

This alias established 320 protocol / 361 supported+strict / 44 AHB paths,
split twenty-two `.ppif` and twenty-two `.ahb`. The later generic exact-three
requester established 321/362/45 and its alias moves current accounting to
322/363/46 split 23/23. New
support-accounted semantics continue to extend one normalized semantic surface
and preserve read-only MCP parity; no feature-specific MCP route or private
payload is added.
