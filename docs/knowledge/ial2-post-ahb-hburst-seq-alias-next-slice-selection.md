---
id: ial2-post-ahb-hburst-seq-alias-next-slice-selection
title: AHB HBURST SEQ alias follow-on selects aggregate propagation readiness audit
answers:
  - "what follows the AHB HBURST SEQ .ahb alias?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.767 select?"
  - "why is aggregate AHB HBURST propagation not implemented directly after the endpoint alias?"
  - "which task audits aggregate AHB HBURST propagation readiness?"
  - "do aggregate byte-lane SEQ interconnects forward subordinate-local HBURST yet?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, aggregate, interconnect, selector]
evidence: docs/IAL2_POST_AHB_HBURST_SEQ_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Adapter/IAL2/PPIF.pm; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.767|IAL2-FEATURE-COMPLETENESS-FRONTIER\.768|aggregate AHB HBURST propagation|HBURST_REGS|HBURST_STATUS|hburst_in_word_progressive|unconnected' docs/IAL2_POST_AHB_HBURST_SEQ_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.767` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.768`, a no-behavior readiness audit for
bounded aggregate AHB HBURST propagation after the endpoint HBURST-aware
byte-lane `SEQ` `.ppif` source and matching `.ahb` alias are both shipped.

The shipped aggregate byte-lane `SEQ` sources still strict-check as-is and
expose requester/top-level `HBURST`, but their child subordinates remain on
the older `in_word_progressive` endpoint contract and have no subordinate-local
burst binding. Temporary aggregate HBURST candidates lowered far enough to
show child `hburst_in_word_progressive` reports, then failed strict checks
closed because `regs.HBURST_REGS` or `status.HBURST_STATUS` was left
unconnected by the composition top.

`.768` must audit subordinate-local HBURST forwarding, top-level connection
policy, `composition.seq_policy_propagation` recognition, source names,
support identities, report/residue movement, tests, docs, and preservation
before any aggregate HBURST behavior changes.
