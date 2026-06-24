---
id: ial2-two-dynamic-one-static-write-demux-readiness
title: Two-dynamic one-static mixed write demux needs contract selection
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.339 select?"
  - "can two-dynamic-plus-static mixed write response demux be implemented directly?"
  - "what comes after the two-dynamic-plus-static write readiness audit?"
  - "why does two-dynamic-plus-static mixed write demux need contract selection?"
date: 2026-06-24
status: current
tags: [ial2, axi, dynamic-id, static-id, response-demux, write, readiness]
evidence: docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_THREE_STATIC_MIXED_DYNAMIC_STATIC_READ_DATA_MULTI_BEAT_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_BROADER_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.339|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.340|TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT|mixed dynamic/static write demux requires one dynamic|mixed dynamic/static ID matching supports exactly one dynamic' docs/AXI_IAL2_MANAGER_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_WRITE_RESPONSE_DEMUX_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.339` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.340`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.

Direct implementation is not selected yet. Current mixed write admission and
constructor logic still require exactly one dynamic write transaction plus
one, two, or three concrete static write transactions, while the
two-dynamic-plus-static shape needs an owned public contract for combining
multi-dynamic active selected-ID uniqueness with static concrete-ID
reservations and dynamic-vs-static exclusions.

The likely later sample stem is:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```
