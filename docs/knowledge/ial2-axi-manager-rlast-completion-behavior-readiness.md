---
id: ial2-axi-manager-rlast-completion-behavior-readiness
title: AXI RLAST behavior readiness selects direct generated completion pulses
answers:
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.52?"
  - "is AXI RLAST generated behavior ready?"
  - "does AXI RLAST need a lower-layer prerequisite?"
  - "what should IAL2-FEATURE-COMPLETENESS-FRONTIER.53 implement?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.53?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, response-demux, behavior, readiness, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.54|AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE|generated burst-last|axi0_rlast|generated_demux_last_beat' docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.52` selected direct generated
burst-last/`RLAST` completion behavior as the next exact slice. No new IAL1,
IAL0, or SystemVerilog prerequisite is required.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.53` shipped the generated `RLAST` input,
generated `RID` input, last-beat transaction completion pulse outputs and
rules, response-demux assertions, report artifacts, auto-ID lifecycle residue
movement, same-ID response-demux coverage movement, and HDL reachability for
`ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`.

The behavior must remain bounded: generated completion pulses fire only for a
matched `RID` beat with asserted `RLAST`; read-data reassembly, beat-count or
`ARLEN` metadata, missing/extra beat validation, per-beat outputs, per-ID
queues, full-manager behavior, direct backend lowering, and VHDL stay deferred.

The immediate next slice after `.53` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.54`, the post-`RLAST` selector. It
selected `.55`, narrow report/static-text alignment, after finding generated
report prose that still described burst-last `RLAST` as report-only. `.55`
shipped that alignment and advanced the frontier to `.56`; `.56` selected
`.57`, public AXI burst read-data contract selection.
