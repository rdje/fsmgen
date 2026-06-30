---
id: ial2-ahb-byte-lane-narrow-transfer-behavior
title: AHB byte-lane subordinate PPIF behavior shipped
answers:
  - "does FSMGen ship AHB byte-lane subordinate behavior?"
  - "what does ppif/ahb_lite_subordinate_byte_lane.ppif generate?"
  - "how does the AHB byte-lane subordinate handle narrow writes and reads?"
  - "what report block describes AHB byte-lane narrow transfer policy?"
date: 2026-06-30
status: current
tags: [ial2, ahb, byte-lane, narrow-transfer, ppif, behavior]
evidence: docs/IAL2_AHB_BYTE_LANE_NARROW_TRANSFER_BEHAVIOR.md; docs/IAL2_AHB_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_lite_subordinate_byte_lane.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1482-ial2-ahb-subordinate-byte-lane.t; t/1475-ial2-ahb-subordinate.t; t/1477-ial2-ahb-subordinate-profile-alias.t; docs/book/src/16c-ial2-ahb.md; docs/book/src/14-feature-backlog.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md
reverify: prove -v t/1482-ial2-ahb-subordinate-byte-lane.t && ./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ppif
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.737` ships the bounded public generic
`.ppif` AHB byte-lane/narrow-transfer subordinate source
`ppif/ahb_lite_subordinate_byte_lane.ppif`.

The source lowers through generated `ahb_lite_subordinate_byte_lane.isf`
before generated `ahb_lite_subordinate_byte_lane.fsm` and emits HDL module
`ahb_lite_subordinate_byte_lane`. It support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane`, source kind `ppif`, and coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli`.

The source accepts byte `HSIZE == 3'b000`, halfword `HSIZE == 3'b001`, and
word `HSIZE == 3'b010` transfers over a single 32-bit register at address 0.
It uses little-endian lane masks, preserves inactive lanes on narrow writes,
zero-fills inactive `HRDATA` lanes on narrow reads, and uses the existing
two-cycle ERROR policy for unsupported size, unsupported transfer, unmapped,
unaligned, and crossing accesses.

The schedule/report JSON includes `narrow_transfer_policy`. The existing
word-only subordinate `.ppif` and `.ahb` alias do not gain that report block.
The matching byte-lane `.ahb` profile alias is documented by
`docs/knowledge/ial2-ahb-byte-lane-profile-alias-behavior.md`.
