---
id: ial2-ahb-aggregate-byte-lane-seq-behavior
title: AHB aggregate byte-lane SEQ PPIF propagation behavior shipped
answers:
  - "does FSMGen ship AHB aggregate byte-lane SEQ propagation?"
  - "what does ppif/ahb_interconnect_byte_lane_seq.ppif generate?"
  - "what does ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif generate?"
  - "how is aggregate byte-lane SEQ propagation reported?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, seq, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_SEQ_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1488-ial2-ahb-interconnect-byte-lane-seq.t; t/1484-ial2-ahb-interconnect-byte-lane.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1488-ial2-ahb-interconnect-byte-lane-seq.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.758` ships generic `.ppif` AHB aggregate
byte-lane in-word `SEQ` propagation through
`ppif/ahb_interconnect_byte_lane_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`.

Both sources lower through generated `.isf` before generated `.fsm` review
artifacts and select HDL module `ahb_tb`. The one-subordinate source embeds
`ahb_lite_subordinate_byte_lane_seq`; the two-subordinate source embeds
`ahb_status_subordinate_byte_lane_seq` and
`ahb_control_subordinate_byte_lane_seq`.

Reports preserve `composition.byte_lane_propagation` and add
`composition.seq_policy_propagation` with
`subordinate_owned_in_word_seq_policy`, local-address-before-SEQ policy,
selected-subordinate mapped-hit ownership, interconnect-owned unmapped ERROR
ownership, `supported_seq_size`, and child `seq_policy` propagation. Child
reports carry both `narrow_transfer_policy` and `transfer.seq_policy`.

Matching aggregate `.ahb` aliases for the aggregate byte-lane `SEQ` sources
remain deferred after `.758`.
