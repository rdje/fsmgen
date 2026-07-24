---
id: ial2-ahb-exact-two-paired-busy-composition-profile-alias-behavior
title: Exact-two paired AHB BUSY composition ships through a byte-identical .ahb alias
answers:
  - "does the exact-two paired AHB BUSY .ahb alias ship?"
  - "what is ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb?"
  - "is the exact-two paired AHB alias a separate generator?"
  - "what support id owns the exact-two paired .ahb alias?"
  - "can MCP semantically introspect the exact-two paired AHB alias?"
  - "how many AHB IAL2 paths ship after the exact-two paired alias?"
  - "which test proves the exact-two paired alias?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, subordinate, interconnect, busy, exact-two, profile-alias, semantics, mcp]
evidence: docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1523-ial2-ahb-exact-two-paired-busy-composition.t; t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-AHB-EXACT-TWO-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md
reverify: cmp ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
---

`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb`
ships as a byte-identical profile alias of the generic exact-two paired source.
Both use the existing requester, subordinate, interconnect, and top generators
through IAL2 -> IAL1 -> IAL0 -> HDL; the alias is source data, not another
generator.

The alias preserves numeric requester-child `busy_insertion.beats=2`,
subordinate and propagated `parks_on=[busy]`, three children, module `ahb_tb`,
and semantic root `top`. Existing suffix handling removes only alias-specific
residue.

Its support ID is
`intent.ahb_profile_alias_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park`
and source kind is `ial2_profile_alias`. Focused t/1524 proves strict check,
schedule, normalized semantic JSON, real read-only MCP, artifact, verifier,
diagnostic, and preservation parity without a second runtime. t/1523 remains
the shared exact-two generated-HDL runtime proof.

That alias established the 318/359/42 checkpoint. The generic two-subordinate
exact-two source established 319/360/43; its matching alias now moves current
accounting to 320 protocol fixtures, 361 supported-smoke/strict fixtures, and
44 AHB IAL2 paths split between twenty-two `.ppif` and twenty-two `.ahb`. New
support-accounted semantics continue to extend the one
normalized semantic surface and preserve read-only MCP parity; no
feature-specific MCP route or private payload is added.
