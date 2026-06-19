---
id: ial2-axi-manager-post-multiple-mixed-depth3-runtime-validation-next-slice-selection
title: Post multiple/mixed depth-3 runtime validation selector chooses support residue cleanup
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.187 select?"
  - "what is the next IAL2 frontier after multiple/mixed depth-3 runtime validation?"
  - "what stale support residue remains after multiple/mixed depth-3 runtime validation?"
  - "why is support residue cleanup next after multiple/mixed depth-3 runtime validation?"
date: 2026-06-19
status: current
tags: [ial2, axi, manager, read-data, burst-last, queue-head, depth-3, runtime-validation, support-residue, selector]
evidence: docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.187|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.188|POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION|read burst-last read-data consumption over multiple or mixed depth-3 queue-head groups with runtime validation or multi-beat payload|selected multiple/mixed depth-3 read burst-last queue-head groups' docs/AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.187` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.188`, report/static support-residue
cleanup after generated runtime beat-count/`RLAST` validation over
multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data.

The live `.186` samples generate runtime validation and remove
`generated_beat_count_validation` from `read_data.residue`, but the static AXI
ID/order unsupported-residue detail still says runtime validation or
multi-beat payload over multiple/mixed depth-3 queue-head groups remains
outside the shell. The runtime-validation part is stale after `.186`; the
multi-beat payload part remains deferred.

`.188` should update only support/report static wording and focused
expectations. Parser syntax, queue-head admission, generated read-data rules,
generated assertions, PPIF corpus membership, support-accounting counts,
generated artifacts, and HDL behavior remain unchanged until separately
owned.
