---
id: ial2-axi-manager-read-burst-last-depth3-runtime-validation-readiness
title: Read burst-last depth-3 queue-head runtime validation readiness selects direct implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.164 select?"
  - "can read burst-last depth-3 runtime validation ship directly?"
date: 2026-06-17
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, burst-length]
evidence: docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.164|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.165|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT|READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR|runtime beat-count|runtime-assertion' docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md docs/AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.164` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.165`, direct bounded implementation of
generated runtime beat-count/`RLAST` validation over one read burst-last
depth-3 queue-head read-data group with raw-`ARLEN` burst-length metadata.

The audit found that the temporary depth-3 runtime-validation candidate fails
only at the local queue-head last-beat coverage diagnostic. Below that gate,
runtime-validation normalization, beat-count storage, beat-count rules,
assertion generation, and report artifact collection already iterate the
covered transaction list.

`.165` then shipped the support-accounted public runtime-validation PPIF
sample for the `r0`/`r1`/`r2` concrete `RID` `3` depth-3 group, generating
expected-beat storage, read-beat counters, beat-count init/increment rules,
and four beat-count/`RLAST` assertions per transaction while keeping
multi-beat, write depth-3, multiple/mixed depth-3 groups, direct backend, and
VHDL deferred.
