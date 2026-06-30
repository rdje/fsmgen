---
id: ial2-post-ahb-aggregate-byte-lane-alias-next-slice-selection
title: Post AHB aggregate byte-lane alias selector chooses nested residue contract
answers:
  - "what follows AHB aggregate byte-lane .ahb aliases?"
  - "which task owns AHB aggregate alias nested residue cleanup?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.746 select?"
  - "why is AHB nested profile-alias residue next?"
  - "what residue remains inside aggregate AHB .ahb child reports?"
date: 2026-06-30
status: current
tags: [ial2, ahb, interconnect, aggregate, byte-lane, profile-alias, residue, task-tree]
evidence: docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md; docs/IAL2_AHB_AGGREGATE_BYTE_LANE_PROFILE_ALIAS_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane.ahb; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ahb && ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.746|IAL2-FEATURE-COMPLETENESS-FRONTIER\.747|ahb_profile_alias_deferred|ahb_subordinate_profile_alias_deferred|nested profile-alias residue' docs/IAL2_POST_AHB_AGGREGATE_BYTE_LANE_ALIAS_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.746` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.747`, public report-contract selection for
AHB aggregate `.ahb` alias nested profile-alias residue cleanup.

After `.745`, top aggregate byte-lane `.ahb` reports remove
`ahb_aggregate_profile_alias_deferred`, but nested generated child reports
still carry endpoint profile-alias residues:
`ahb_profile_alias_deferred` for the requester child and
`ahb_subordinate_profile_alias_deferred` for subordinate children.

`.747` must choose the exact cleanup contract and preservation boundary before
any implementation change. Optional signals, burst `SEQ`, broader AHB
interconnect/decode, legacy two-bit subordinate `HRESP`, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, and VHDL remain
future task-tree-owned work.
