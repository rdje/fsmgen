---
id: ial2-axi-manager-multiple-mixed-depth3-runtime-validation-support-residue-cleanup
title: Multiple/mixed depth-3 runtime validation support residue is cleaned
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.188 clean?"
  - "is multiple/mixed depth-3 runtime validation still unsupported residue?"
  - "what remains deferred after multiple/mixed depth-3 runtime validation residue cleanup?"
date: 2026-06-19
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, support-residue]
evidence: docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md; docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.188|RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP|read burst-last multi-beat payload over multiple or mixed depth-3 queue-head groups|read burst-last read-data consumption over multiple or mixed depth-3 queue-head groups with runtime validation or multi-beat payload' docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.188` cleaned stale AXI manager
support/residue wording after `.186`.

Generated runtime beat-count/`RLAST` validation over selected multiple/mixed
depth-3 read burst-last queue-head scalar last-beat read-data is now described
as supported in the static support detail. The stale phrase that grouped
runtime validation with multi-beat payload as unsupported residue is gone from
the generated report text and remains only as a negative test literal.

Multi-beat payload over multiple/mixed depth-3 queue-head groups remains
deferred behind a future exact owner.
