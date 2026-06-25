---
id: ial2-dynamic-read-burst-last-depth3-same-id-issue-order-queue-read-data-runtime-validation-readiness-audit
title: Depth-3 dynamic RLAST queue raw-ARLEN runtime-validation readiness audit selects direct implementation
answers:
  - "is runtime validation over depth-3 dynamic RLAST queue raw ARLEN read-data ready?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.496 select?"
  - "what blocks depth-3 dynamic RLAST queue runtime validation today?"
  - "does FSMGen need sv2v for depth-3 dynamic RLAST queue runtime validation?"
date: 2026-06-25
status: current
tags: [ial2, axi, manager, dynamic-id, same-id-ordering, issue-order-queue, rlast, read-data, burst-length, arlen, runtime-validation, readiness-audit]
evidence: docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_POST_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_NEXT_SLICE_SELECTION.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_BURST_LENGTH_BEHAVIOR.md; docs/AXI_IAL2_MANAGER_DYNAMIC_READ_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_BEHAVIOR.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; MEMORY.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.496|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.497|DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT|report-only burst_length metadata over one depth-3 all-dynamic queue|axi0_r2_expected_beats_q|sv2v' docs/AXI_IAL2_MANAGER_DYNAMIC_READ_BURST_LAST_DEPTH3_SAME_ID_ISSUE_ORDER_QUEUE_READ_DATA_RUNTIME_VALIDATION_READINESS_AUDIT.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md MEMORY.md
---

`.496` selects `.497`, direct bounded implementation of runtime
beat-count/`RLAST` validation over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` scalar read-data
raw-`ARLEN` behavior shipped in `.494`.

The audit found only a local coverage predicate blocker: the depth-3 dynamic
queue branch admits report-only raw-`ARLEN`, while runtime-assertion
raw-`ARLEN` is still rejected. A temporary one-line predicate overlay proved
the existing runtime helpers enumerate `r0`/`r1`/`r2` expected-beat storage,
read-beat counters, six rules, and twelve beat-count/`RLAST` assertions.
FSMGen-owned generation/lowering remains the default; `sv2v` is not selected
as a dependency.
