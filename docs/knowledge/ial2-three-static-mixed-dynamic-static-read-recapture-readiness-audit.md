---
id: ial2-three-static-mixed-dynamic-static-read-recapture-readiness-audit
title: Three-static mixed read recapture readiness audit
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.417 decide?"
  - "is three-static mixed read recapture ready for contract selection?"
  - "what blocks direct three-static mixed read recapture implementation?"
  - "what should the three-static mixed read recapture contract pin?"
date: 2026-06-24
status: current
tags: [ial2, axi, manager, dynamic-id, mixed-dynamic-static, read, recapture, readiness]
evidence: docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.417|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.418|THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT|read_mixed_dynamic_static_response_demux_multi_static3\\.ppif|generated_multi_mixed_dynamic_static_read_demux_completion|static_capture\\[\\]|one or two static states|contract selection' docs/AXI_IAL2_MANAGER_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.417` selects `.418`, public contract
selection for one-dynamic-plus-three-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture.

The audit found no lower parser, PPIF syntax, support-accounting,
report-schema, or IAL1/HDL prerequisite before contract selection. The public
sample and list-shaped report mode already ship through `.322`, and the rule
and assertion helpers already compose over the dynamic/static request and
static-ID guard arrays.

The current implementation cap is deliberate selection logic: the single-beat
normalizer and mixed read recapture marker only select one dynamic plus one or
two static read states, and the focused expectation helper still treats the
three-static sample as no-recapture.

The `.418` contract must pin the public syntax/support identity, list-shaped
`static_capture[]` for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, dynamic guards
across three static requests and static-ID exclusions, static guards across
the dynamic request and both sibling static requests, idle-or-releasing
assertions for `r0`/`r1`/`r2`/`r3`, preservation boundaries, validation
gates, rollback, docs, and Knowledge Map impact before behavior changes.
