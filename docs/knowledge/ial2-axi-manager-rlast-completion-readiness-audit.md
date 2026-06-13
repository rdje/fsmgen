---
id: ial2-axi-manager-rlast-completion-readiness-audit
title: AXI RLAST readiness audit selects public contract before behavior
answers:
  - "what did the AXI RLAST readiness audit decide?"
  - "can FSMGen implement AXI RLAST behavior directly?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.49?"
  - "why is AXI burst behavior not implemented after read-data capture?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, bursts, read-data, completion, contract, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.50|AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT|public AXI burst/`RLAST` completion contract|rlast_completion' docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.49` audited AXI burst/`RLAST`
completion readiness after generated single-beat read-data capture.

The audit selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.50`: public AXI
burst/`RLAST` completion contract selection. Direct parser/report metadata or
generated behavior is premature because the public source contract has not
selected `RLAST` signal ownership, burst length or beat-count metadata,
beat-valid versus transaction-complete pulse semantics, data/status capture
granularity, diagnostics, generated artifact boundaries, or report/residue
movement.

No new IAL1/IAL0/SystemVerilog substrate prerequisite is evident for a later
bounded implementation once the contract exists. Existing width-bearing ports,
scalar storage, guarded rule assignments, and one-cycle pulses can likely
carry `RLAST` inputs, beat counters, last-beat completion pulses, and
assertions. The missing piece is public AXI semantics, not a known lowering
gap.

The shipped read side remains single-beat today. Schedule JSON for
`ppif/axi_manager_capacity_status_read_data.ppif` still reports
`response_demux.read.response_scope: single_beat`,
`read_data.generated_behavior: true`, and `read_data.residue` containing
`rlast_completion`, `bursts`, and `multi_beat_read_data_reassembly`.
VHDL stays deferred until the SystemVerilog-backed IAL path is feature
complete.
