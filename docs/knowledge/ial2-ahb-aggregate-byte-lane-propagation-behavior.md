---
id: ial2-ahb-aggregate-byte-lane-propagation-behavior
title: AHB aggregate byte-lane PPIF propagation behavior shipped
answers:
  - "does FSMGen ship AHB aggregate byte-lane propagation?"
  - "what does ppif/ahb_interconnect_byte_lane.ppif generate?"
  - "what does ppif/ahb_interconnect_two_subordinate_byte_lane.ppif generate?"
  - "how is aggregate byte-lane propagation reported?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, narrow-transfer, behavior]
evidence: docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROPAGATION_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane.ppif; ppif/ahb_interconnect_two_subordinate_byte_lane.ppif; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1484-ial2-ahb-interconnect-byte-lane.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -Iperl t/1484-ial2-ahb-interconnect-byte-lane.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.743` ships generic `.ppif` AHB aggregate
byte-lane/narrow-transfer propagation through
`ppif/ahb_interconnect_byte_lane.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane.ppif`.

Both sources lower through generated `.isf` before generated `.fsm` review
artifacts and select HDL module `ahb_tb`. The one-subordinate source embeds
`ahb_lite_subordinate_byte_lane`; the two-subordinate source embeds
`ahb_status_subordinate_byte_lane` and
`ahb_control_subordinate_byte_lane`.

The aggregate report adds `composition.byte_lane_propagation` with
`subordinate_owned_narrow_transfer_policy`, local-address-before-lane policy,
selected-subordinate mapped-hit ownership, interconnect-owned unmapped ERROR
ownership, and child `narrow_transfer_policy` propagation. Existing word-only
aggregate `.ppif` and `.ahb` sources do not gain that block.

Matching `.ahb` aliases for the aggregate byte-lane sources were not shipped
by `.743`; they are documented separately by the `.745` behavior card after
that follow-on slice shipped.
