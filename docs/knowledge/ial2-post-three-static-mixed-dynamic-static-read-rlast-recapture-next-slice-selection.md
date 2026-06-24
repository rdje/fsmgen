---
id: ial2-post-three-static-mixed-dynamic-static-read-rlast-recapture-next-slice-selection
title: Post three-static mixed read RLAST recapture next slice selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.424 select?"
  - "what is next after three-static mixed read RLAST recapture shipped?"
  - "why is two-dynamic-plus-one-static mixed read recapture next?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.425 audit?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, selection]
evidence: docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.424|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.425|POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION|two-dynamic-plus-one-static mixed dynamic/static read single-beat|multi_dynamic\\.ppif|request_not_busy_assertions|idle_or_releasing_assertions|static_capture_present' docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.424` selects `.425`, readiness audit for
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The selector changes no behavior. A direct adapter/report probe confirmed
the current single-beat and burst-last two-dynamic-plus-one-static mixed read
reports still have no dynamic release-recapture fields, no `static_capture`,
three request-not-busy assertions, and zero idle-or-releasing assertions.

This is next because `.423` completes the one-dynamic mixed read recapture
ladder across one-static, two-static, and three-static cardinalities for both
single-beat and burst-last shapes, while `.407` already shipped the
two-dynamic-plus-one-static write recapture sibling.

`.425` should audit the single-beat read shape first because it exercises
multi-dynamic selected-ID recapture, active same-ID blocking, static concrete
busy recapture, onehot0 mixed request policy, no-active-same-ID assertions,
and active dynamic-ID uniqueness without adding final-only `RLAST` release
source or raw non-final `RID` preservation questions.
