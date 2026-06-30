---
id: ial2-ahb-hburst-length-wrap-seq-behavior
title: AHB HBURST WRAP4/INCR4 byte-lane SEQ source is shipped
answers:
  - "is AHB HBURST SEQ supported?"
  - "which AHB source supports HBURST WRAP4 INCR4 SEQ?"
  - "what does ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif do?"
  - "what is hburst-in-word-progressive?"
  - "does the AHB HBURST byte-lane SEQ source have an .ahb alias?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, behavior, byte-lane]
evidence: docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_BEHAVIOR.md; docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.764` ships the generic `.ppif` source
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`.

It support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq`, lowers through
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` and
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, and emits HDL module
`ahb_lite_subordinate_byte_lane_hburst_seq`.

The source adds subordinate bus binding `(burst HBURST width 3)` and transfer
policy `(seq-policy hburst-in-word-progressive)`. Its report exposes
`bindings.bus.burst` plus `transfer.seq_policy.mode =
hburst_in_word_progressive`, with byte-only `WRAP4`/`INCR4` support inside
one 32-bit register word.

`SINGLE` remains independent `NONSEQ` only and never arms `SEQ` history.
Standalone `SEQ`, `SEQ` after `SINGLE`/reset/IDLE/BUSY/ERROR, changed
`HBURST`/`HWRITE`/`HSIZE`, unexpected address progression, unsupported
HBURST modes, halfword/word burst `SEQ`, unsupported size, unmapped,
unaligned, and crossing accesses fail closed with the selected two-cycle ERROR
response.

The matching `.ahb` alias, aggregate propagation, BUSY-in-burst parking,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.
