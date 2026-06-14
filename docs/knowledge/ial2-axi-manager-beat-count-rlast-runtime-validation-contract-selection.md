---
id: ial2-axi-manager-beat-count-rlast-runtime-validation-contract-selection
title: AXI beat-count/RLAST runtime validation selects runtime-assertion mode
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.68 select?"
  - "what validation mode enables AXI beat-count RLAST runtime checks?"
  - "what is the normalized report value for validation runtime-assertion?"
  - "does validation runtime-assertion ship as metadata only?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.68?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.69?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, rlast, beat-count, validation, runtime-assertion, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.68|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.69|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.70|validation runtime-assertion|runtime_assertion|BEAT_COUNT_RLAST_RUNTIME_VALIDATION_(CONTRACT_SELECTION|FIRST_SLICE)' docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.68` selected
`(validation runtime-assertion)` as the explicit public AXI read-data
beat-count/RLAST generated-validation mode. The normalized report value is
`runtime_assertion`.

Existing `(validation report-only)` remains valid, normalizes to
`report_only`, and continues to mean no generated beat-count/RLAST runtime
checks.

`runtime-assertion` is behavior-bearing. The implementation owner must not
accept the syntax as metadata only; parser support, generated expected-count
storage, beat-count state, matched-beat rules, runtime assertions, report
fields, tests, and mdBook sync must ship together. That implementation shipped
in `IAL2-FEATURE-COMPLETENESS-FRONTIER.69`.

The next active leaf after `.69` is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.70`, a selector for the next exact AXI
manager feature-completeness owner.
