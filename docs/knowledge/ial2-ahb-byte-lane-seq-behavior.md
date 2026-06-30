---
id: ial2-ahb-byte-lane-seq-behavior
title: AHB byte-lane in-word SEQ source is shipped
answers:
  - "is AHB subordinate SEQ supported?"
  - "which AHB source supports byte-lane SEQ?"
  - "what does ppif/ahb_lite_subordinate_byte_lane_seq.ppif do?"
  - "what is transfer.seq_policy for AHB?"
  - "does AHB byte-lane SEQ have an .ahb alias?"
date: 2026-06-30
status: current
tags: [ial2, ahb, burst, seq, behavior, byte-lane]
evidence: docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1486-ial2-ahb-subordinate-byte-lane-seq.t; docs/book/src/16c-ial2-ahb.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; MEMORY.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.752` ships the generic `.ppif` source
`ppif/ahb_lite_subordinate_byte_lane_seq.ppif`.

It support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane_seq`, lowers through
`ahb_lite_subordinate_byte_lane_seq.isf` and
`ahb_lite_subordinate_byte_lane_seq.fsm`, and emits HDL module
`ahb_lite_subordinate_byte_lane_seq`.

The source keeps `supported-transfer nonseq` for compatibility and adds
`(seq-policy in-word-progressive)`. Its report exposes structured
`transfer.seq_policy` for byte/halfword-only in-word continuation after a
prior OKAY `NONSEQ` or valid `SEQ`, expected next address, and stable
`HWRITE`/`HSIZE`.

Standalone `SEQ`, `SEQ` after reset/IDLE/BUSY/ERROR, word `SEQ`, crossing,
unexpected address, changed control, unsupported size, unmapped, unaligned,
and crossing accesses fail closed with the selected two-cycle ERROR response.
No matching `.ahb` alias or aggregate propagation is shipped yet.
