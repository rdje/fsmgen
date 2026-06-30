---
id: ial2-post-ahb-byte-lane-seq-alias-next-slice-selection
title: AHB byte-lane SEQ alias follow-on selects aggregate SEQ readiness
answers:
  - "what comes after the AHB byte-lane SEQ .ahb alias?"
  - "which AHB task follows IAL2-FEATURE-COMPLETENESS-FRONTIER.754?"
  - "is aggregate AHB SEQ propagation next?"
  - "does .755 change AHB behavior?"
date: 2026-06-30
status: current
tags: [ial2, ahb, selector, aggregate, seq, byte-lane]
evidence: docs/IAL2_POST_AHB_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_seq.ahb; ppif/ahb_interconnect_byte_lane.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane.ppif; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.755|IAL2-FEATURE-COMPLETENESS-FRONTIER\.756|aggregate byte-lane in-word `SEQ` propagation|ahb_interconnect_byte_lane_seq' docs/IAL2_POST_AHB_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.755` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.756`, a no-behavior readiness audit for
bounded AHB aggregate byte-lane in-word `SEQ` propagation.

The selector changes no parser, generator, public source, support-accounting,
capability-manifest, schedule/check/semantic JSON, generated artifact, HDL, or
runtime behavior.

The selected audit follows the established AHB order:
endpoint `.ppif`, endpoint `.ahb`, then aggregate propagation readiness. It is
chosen before HBURST length/wrap, BUSY-in-burst, multi-word/register-bank,
optional signals, broader interconnect/decode, direct backend,
verification-output, AXI/APB, broader AHB, or VHDL work.
