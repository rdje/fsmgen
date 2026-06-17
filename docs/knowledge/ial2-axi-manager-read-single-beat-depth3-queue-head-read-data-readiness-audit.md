---
id: ial2-axi-manager-read-single-beat-depth3-queue-head-read-data-readiness-audit
title: AXI manager read single-beat depth-3 queue-head read-data readiness selects direct implementation
answers:
  - "can read-data over read single-beat depth-3 queue-head demux be implemented directly?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.152 select?"
  - "what blocked depth-3 queue-head read-data during the .152 audit?"
  - "what is the next IAL2 frontier after the depth-3 read-data readiness audit?"
date: 2026-06-17
status: current
tags: [ial2, axi, read-data, queue-head, depth-3, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.152|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.153|depth-3 read-data|queue-head single-beat coverage requires one or more depth-2|one selected generated depth-3' docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.152` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.153`, generated scalar read-data over one
read single-beat depth-3 queue-head response-demux group.

The shipped depth-3 response-demux sample remains generated and
support-accounted with `r0`, `r1`, and `r2` in one concrete `RID` group, but it
does not contain `read_data`. During `.152`, a temporary scalar read-data probe
for that shape failed closed at the explicit depth-2 queue-head read-data
coverage gate. `.153` later shipped the selected one-group scalar read-data
sibling.

The readiness audit found that downstream generated read-data inputs, scalar
outputs, capture rules, report fields, `.fsm` lowering, and SystemVerilog HDL
paths already iterate covered transactions after coverage admits them. The
next bounded owner is therefore a local coverage widening for one depth-3 read
single-beat group, not a parser, lowerer, report, or HDL substrate prerequisite.
