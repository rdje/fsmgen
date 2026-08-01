---
id: ial2-ahb-hburst-length-wrap-seq-readiness-audit
title: AHB HBURST length/wrap SEQ readiness selects endpoint contract
answers:
  - "is AHB HBURST length wrap SEQ ready for implementation?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.762 select?"
  - "does AHB subordinate SEQ currently carry HBURST?"
  - "should AHB HBURST SEQ start endpoint-only or aggregate-inclusive?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, readiness, contract-selection]
evidence: >-
  docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT.md; docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_SEQ_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_SEQ_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_SEQ_BEHAVIOR.md; docs/IAL2_AHB_BURST_SEQ_CONTRACT_SELECTION.md; ppif/ahb_lite_subordinate_byte_lane_seq.ppif; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; t/1486-ial2-ahb-subordinate-byte-lane-seq.t; t/1488-ial2-ahb-interconnect-byte-lane-seq.t;
  docs/book/src/16c-ial2-ahb.md; README.md; ROADMAP_V2.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md
reverify: rg -n "IAL2-FEATURE-COMPLETENESS-FRONTIER\\.762|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.763|HBURST-aware byte-lane|subordinate_hburst_refs=0|unsupported clause" docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/book/src/16c-ial2-ahb.md MEMORY.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.762` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.763`, a no-behavior public contract
selection for a new endpoint-only HBURST-aware byte-lane `SEQ` source family.

The current requester already drives `HBURST` and computes increment/wrap
address progression, but the selected subordinate byte-lane `SEQ` bus has no
`HBURST` binding. A candidate subordinate `(burst HBURST width 3)` clause
currently fails closed as an unsupported bus clause. The aggregate interconnect
sees global `HBURST`, but generated interconnect output has no
subordinate-local `HBURST_*` forwarding.

The first safe path is a new generic endpoint source and public contract
selection. Existing byte-lane in-word `SEQ` sources stay preserved, aggregate
HBURST propagation and matching `.ahb` aliases remain later owners, and
BUSY-in-burst plus multi-word/register-bank progression remain deferred.
