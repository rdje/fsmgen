---
id: ial2-ahb-subordinate-busy-park-contract-selection
title: AHB subordinate BUSY-in-burst parking contract selection picks a new additive source stem
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.775 select?"
  - "what is the public contract for the AHB subordinate BUSY-parking source?"
  - "how does the .ppif declare that HTRANS=BUSY parks the burst rather than clearing it?"
  - "does AHB BUSY-parking add a new source or widen the shipped hburst_seq source?"
  - "how is a drifting BUSY-then-SEQ resume fail-closed?"
date: 2026-07-12
status: current
tags: [ial2, ahb, hburst, seq, busy, parking, subordinate, contract-selection]
evidence: docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md; docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_READINESS_AUDIT.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; t/248-regression-corpus-accounting.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.775|IAL2-FEATURE-COMPLETENESS-FRONTIER\.776|parked-transfer|parked_transfer|busy_park|parks_on|seq_ok_base' docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.775` selects the public contract for the
endpoint AHB subordinate BUSY-in-burst parking source and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.776`, its direct implementation.

The source is a new additive stem
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` (support identity
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`, coverage key
`ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
source kind `ppif`), preserving the shipped source and its `t/1491` assertions.
It replaces `(ignored-transfer busy)` with the new `(parked-transfer busy)`
vocabulary (parallel to `(ignored-transfer idle)`).

The parser (`AhbSubordinate::_normalize_transfer`, `:214`) adds an optional
`parked_transfer` field and relaxes the `{idle,busy}`-only ignored validation
(`:221`) to accept `ignored={idle}`+`parked={busy}`. The generator makes
`ahb_seq_idle_clear` (`:708`) fire only on IDLE, so a BUSY beat holds (unassigned
registers retain value) rather than clears. No drift check on the BUSY beat: the
existing `SEQ`-beat `seq_ok_base` validation (`:526`) fail-closes a mismatched
resume. The report (`:974`) drops `busy` from `clears_on` and adds
`parks_on=[busy]`, and the residue narrows to drop "BUSY-in-burst continuation" —
both gated on the parked-BUSY flag. `.776` adds focused `t/1494`, bumps `t/248`
counts (291→292 protocol, 332→333 total) and the `t/297` manifest, and syncs
docs. The matching `.ahb` alias, aggregate BUSY-parking, and requester-side BUSY
insertion remain deferred.
