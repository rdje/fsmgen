---
id: ial2-ahb-aggregate-hburst-seq-behavior
title: AHB aggregate HBURST SEQ PPIF propagation behavior shipped
answers:
  - "does FSMGen ship AHB aggregate HBURST SEQ propagation?"
  - "what does ppif/ahb_interconnect_byte_lane_hburst_seq.ppif generate?"
  - "what does ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif generate?"
  - "how is aggregate HBURST SEQ propagation reported?"
date: 2026-06-30
status: current
tags: [ial2, ahb, hburst, seq, aggregate, interconnect, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif; ppif/ahb_interconnect_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t; t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.770` ships generic `.ppif` AHB aggregate
HBURST-aware byte-lane `SEQ` propagation through
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`.

Both sources lower through generated `.isf` before generated `.fsm` review
artifacts and select HDL module `ahb_tb`. The one-subordinate source embeds
`ahb_lite_subordinate_byte_lane_hburst_seq`; the two-subordinate source embeds
`ahb_status_subordinate_byte_lane_hburst_seq` and
`ahb_control_subordinate_byte_lane_hburst_seq`.

Requester/global `HBURST` fans out directly to child-local `HBURST_REGS`,
`HBURST_STATUS`, and `HBURST_CONTROL` as applicable. Reports preserve
`composition.byte_lane_propagation` and reuse
`composition.seq_policy_propagation` with
`subordinate_owned_hburst_in_word_seq_policy`, `length_source: HBURST`,
request-forwarding `burst`, child `bindings.bus.burst`, child
`transfer.seq_policy`, `supported_hburst_modes`, and fail-closed HBURST mode
metadata.

The matching aggregate `.ahb` aliases now ship through `.772`; current alias
behavior is documented in
`IAL2_AHB_AGGREGATE_HBURST_SEQ_PROFILE_ALIAS_BEHAVIOR`. Remaining burst work
starts beyond the selected byte-only aggregate HBURST and BUSY-parking
variants, not at alias exposure.
