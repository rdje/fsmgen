---
id: ial2-post-requester-wrap-repair-next-owner-selection
title: Post-WRAP selection prioritizes current AHB book and behavior truthfulness
answers:
  - "what follows the AHB requester WRAP progression repair?"
  - "which task owns stale AHB aggregate alias deferrals in the mdBook?"
  - "why is AHB documentation truthfulness repaired before boundary-free pipelining?"
  - "which AHB aliases ship despite current documents saying they are deferred?"
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.805 select?"
date: 2026-07-23
status: current
tags: [ial2, ahb, mdbook, documentation, alias, truthfulness, selection]
evidence: docs/IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/16c-ial2-ahb.md; docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md; docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md; docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md; ppif/ahb_interconnect_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb; ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb; ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb; t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t; t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t; t/1514-ial2-ahb-paired-busy-composition-profile-alias.t; t/1516-ial2-ahb-two-subordinate-paired-busy-composition-profile-alias.t; docs/TASK_TREE.md; MEMORY.md
reverify: rg --files ppif t | rg '(^ppif/ahb_interconnect(_two_subordinate)?_byte_lane_hburst_seq(_busy_park)?\.ahb$|^ppif/ahb_interconnect_requester_busy_insert(_two_subordinate)?_byte_lane_hburst_seq_busy_park\.ahb$|^t/149[37]-|^t/151[46]-)' && rg -n 'except the aggregate HBURST and aggregate BUSY-park aliases|matching aggregate HBURST `.ahb` aliases remain deferred|matching `.ahb` alias remains later' docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/16c-ial2-ahb.md docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md
---

After the requester WRAP repair, `.805` found that all selected aggregate
HBURST, aggregate BUSY-park, and paired BUSY `.ahb` aliases ship and have
focused parity tests, but several current mdBook/behavior/fact surfaces still
defer them. The same AHB chapter's thirty-eight-source inventory already lists
the aliases, proving an internal current-truth contradiction.

`.805` selects `.806` to repair only current user-facing and canonical behavior
truth, preserve historical slice records, and add focused t/1518 drift coverage.
The existing `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT` remains proposed behind
that smaller prerequisite. No generator/runtime/public-source behavior changes
in the selector; decision 0020 stays inactive.
