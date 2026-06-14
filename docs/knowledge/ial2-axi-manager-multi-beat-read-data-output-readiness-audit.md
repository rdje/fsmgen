---
id: ial2-axi-manager-multi-beat-read-data-output-readiness-audit
title: AXI multi-beat read-data output-bank behavior needs no lower-layer prerequisite
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.73 decide?"
  - "can AXI multi-beat read-data output-bank behavior be implemented next?"
  - "does AXI multi-beat read-data need an IAL1 prerequisite before generated outputs?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.73?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.74?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, multi-beat, output-bank, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.73|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.74|MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT|output-bank behavior|constant prefix' docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.73` audited generated AXI multi-beat
read-data output-bank behavior readiness and found no new
IAL1/IAL0/SystemVerilog prerequisite for the first generated behavior slice.

The selected implementation boundary was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.74`. `.74` has since shipped generated
`RDATA`/`RRESP` inputs, scalar per-beat data/status output lanes, valid-mask
outputs, length outputs, request-time output-bank clearing, and lane-specific
capture rules.

The first behavior slice should use public output registers as the generated
per-transaction beat storage. Each lane capture guard should combine the
response-demux matched-read-beat expression, `!request_event`, and current
`beat_count_storage == lane_index`. Valid masks should use constant prefix
values, so no dynamic indexed LHS assignment, array output, or dynamic shift
is required.

In `.74`, `multi_beat_read_data_reassembly` and `per_beat_outputs` left
residue for the multi-beat sample. Scalar `RRESP` aggregation, per-ID queues,
direct backend lowering, and VHDL remain deferred.
