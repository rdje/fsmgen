---
id: ial2-ahb-paired-busy-composition-profile-alias-behavior
title: The paired AHB BUSY composition ships through a matching .ahb profile alias
answers:
  - "does FSMGen ship a paired AHB BUSY composition .ahb alias?"
  - "are paired AHB BUSY .ppif and .ahb separate generators?"
  - "what does the paired AHB BUSY .ahb alias generate?"
  - "what support id covers the paired AHB BUSY alias?"
  - "which test proves paired AHB BUSY alias parity?"
  - "does the paired AHB BUSY alias preserve busy_insertion and parks_on?"
date: 2026-07-23
status: current
tags: [ial2, ahb, requester, subordinate, busy, composition, profile-alias, behavior]
evidence: docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1513-ial2-ahb-paired-busy-composition.t; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: cmp ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb && prove -Iperl t/1514-ial2-ahb-paired-busy-composition-profile-alias.t
---

FSMGen ships
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb`
as a byte-identical profile-alias mirror of the generic `.ppif` paired-BUSY
source. They are two public IAL2 entrypoints to the same generator path, not
separate generators.

The alias support id is
`intent.ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park`,
coverage is
`ial2_ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli`,
module `ahb_tb`, child count 3, semantic root `top`. The corpus is 312 protocol
and 353 supported-smoke/strict entries.

The alias preserves the exact generated IAL1/IAL0 artifacts,
requester-child `busy_insertion`, subordinate/aggregate `parks_on=[busy]`, and
t/1513 runtime behavior. Existing suffix handling removes only profile-alias
residue. t/1514 proves parity, public CLI/report/artifact/support surfaces,
diagnostics, and clean `--verify-hdl`.
