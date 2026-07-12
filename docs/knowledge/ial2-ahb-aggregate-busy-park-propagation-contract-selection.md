---
id: ial2-ahb-aggregate-busy-park-propagation-contract-selection
title: AHB aggregate BUSY-park contract ships both interconnect stems in .782
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.781 select?"
  - "what is the public contract for the aggregate AHB BUSY-park sources?"
  - "which aggregate AHB BUSY-park .ppif stems ship and what are their support identities?"
  - "does aggregate AHB BUSY-park need an interconnect generator or parser change?"
  - "which aggregate residue narrows when BUSY-park propagation ships?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, interconnect, aggregate, contract, selector]
evidence: docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_READINESS_AUDIT.md; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.781|IAL2-FEATURE-COMPLETENESS-FRONTIER\.782|ahb_interconnect_byte_lane_hburst_seq_busy_park|parked-transfer busy|BUSY-in-burst handling' docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/Support/RegressionCorpus.pm MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.781` selects the public contract for the
aggregate AHB BUSY-park propagation sources and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.782`, the direct implementation. Both stems
ship in `.782`, mirroring `.770` (which shipped both aggregate HBURST `SEQ`
stems in one slice).

The two additive stems are byte-for-byte copies of the shipped aggregate HBURST
`SEQ` sources with the inlined child transfer `(ignored-transfer busy)` replaced
by `(parked-transfer busy)`:

- `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` — support identity
  `intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`, coverage
  `ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  `source_kind: ppif`, module `ahb_tb`, semantic root `top`, child count 3.
- `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif` —
  support identity
  `intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`,
  coverage
  `ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  child count 4.

The behavior delta is source data plus residue narrowing, with no interconnect
generator/parser/report code change: the `(parked-transfer busy)` vocabulary is
child-role-shared (`AhbSubordinate.pm:224`–`245`), `_seq_policy_propagation_report`
clones the child `seq_policy` verbatim (`AhbInterconnect.pm:1177`, `:1207`) so
`parks_on = [busy]` surfaces automatically, and `.782` narrows only the aggregate
HBURST residue at `AhbInterconnect.pm:1401` (the base non-HBURST `:1403` variant
is untouched). `.782` adds focused `t/1496`, moves `t/248` to 295 protocol / 336
total, extends `t/297`, and preserves `t/1492`/`t/1493`. The matching aggregate
`.ahb` aliases, requester-side BUSY insertion, halfword/word burst `SEQ`,
wider/indefinite bursts, and optional AHB signals remain deferred.
