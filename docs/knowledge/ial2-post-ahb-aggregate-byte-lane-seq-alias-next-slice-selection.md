---
id: ial2-post-ahb-aggregate-byte-lane-seq-alias-next-slice-selection
title: AHB aggregate byte-lane SEQ alias follow-on selects HBURST readiness
answers:
  - "what follows AHB aggregate byte-lane SEQ .ahb aliases?"
  - "which task audits AHB HBURST length wrap readiness?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.761 select?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, seq, hburst, selector]
evidence: docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_seq.ahb; ppif/ahb_interconnect_byte_lane_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.761|IAL2-FEATURE-COMPLETENESS-FRONTIER\.762|HBURST-driven length/wrap|ahb_burst_seq_support_deferred' docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.761` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.762`, a no-behavior readiness audit for
bounded AHB HBURST-driven length/wrap `SEQ` semantics.

The selection follows the `.760` aggregate byte-lane in-word `SEQ` `.ahb`
alias shipment. Endpoint and aggregate `SEQ` alias reports now have profile
alias residue cleaned up, leaving `ahb_burst_seq_support_deferred` as the
front-most shared AHB `SEQ` residue: HBURST length/wrap semantics,
BUSY-in-burst handling, multi-word/register-bank progression, and burst
address progression beyond requester generation remain future work.

`.762` must audit source syntax, HBURST forwarding, bounded burst kinds,
length/wrap windows, whether endpoint-only or aggregate-inclusive behavior is
the first safe subset, diagnostics, report shape, generated review artifacts,
validation, rollback, and explicit deferrals before any behavior change.
