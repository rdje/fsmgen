---
id: ial2-axi-manager-beat-count-rlast-validation-readiness-audit
title: AXI beat-count/RLAST validation needs explicit runtime-validation contract
answers:
  - "can AXI beat-count/RLAST validation be implemented directly after ARLEN capture?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.67 decide?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.67?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.68?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.68?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.69?"
  - "does validation report-only generate runtime checks?"
date: 2026-06-14
status: current
tags: [ial2, axi, manager, read-data, burst-length, arlen, rlast, beat-count, validation, selector, task-tree]
evidence: docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md; docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.67|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.68|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.69|validation report-only|validation runtime-assertion|runtime_assertion|BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION' docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.67` audited beat-count/RLAST validation
readiness after generated raw-ARLEN capture.

The lower layers are ready for a future generated validation behavior slice:
generated storage can carry max-beats-width expected-count and beat-count
state, generated rules can assign arithmetic expressions, response-demux
match expressions can identify every accepted matched read beat, and generated
assertions already lower through clocked reset-disabled SystemVerilog
properties.

The audit did not select direct behavior because the current public syntax is
`validation report-only`, which must remain no-runtime-check behavior. The
`.68` selector then chose `(validation runtime-assertion)` with normalized
report value `runtime_assertion`, preserved `report-only`, and selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.69` as the behavior-bearing
implementation owner.
