---
id: ial2-axi-manager-rlast-completion-behavior-first-slice
title: AXI RLAST behavior ships generated last-beat completion pulses
answers:
  - "is AXI RLAST generated behavior shipped?"
  - "what does response-scope burst-last generate?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.53?"
  - "does burst-last read-data reassembly ship?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, response-demux, behavior, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.53` ships generated burst-last `RLAST`
completion behavior for explicit read response-demux contracts.

For
`ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`, the
generator emits the raw read response beat input, generated `RID` input,
generated `RLAST` input, generated transaction completion pulse outputs, and
one RLAST-gated response-demux rule per read auto-ID transaction.

The generated completion pulses fire only for a raw accepted response beat
whose `RID` matches an active transaction and whose `RLAST` signal is asserted.
The report marks `response_demux.generated_behavior: true`, removes
`generated_burst_last_read_demux` residue, removes `response_demux` from
`auto_id_lifecycle.residue`, and marks the read same-ID family
`response_demux_covered: true`.

This slice does not ship burst read-data reassembly, beat-count or `ARLEN`
ownership, missing/extra beat validation, per-beat outputs, per-ID response
queues, full-manager behavior, direct backend lowering, or VHDL.

The immediate next slice after `.53` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.54`, the post-`RLAST` selector. It
selected `.55`, narrow report/static-text alignment, after finding generated
report prose that still described burst-last `RLAST` as report-only. `.55`
shipped that alignment and advanced the frontier to `.56`; `.56` selected
`.57`, public AXI burst read-data contract selection.
