---
id: ial2-axi-manager-rlast-completion-metadata-first-slice
title: AXI RLAST metadata slice ships parser and report validation only
answers:
  - "is AXI RLAST parser metadata supported?"
  - "does response-scope burst-last generate RLAST behavior?"
  - "what PPIF sample covers AXI RLAST metadata?"
  - "can read-data be combined with burst-last response-demux?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.51?"
  - "what comes after IAL2-FEATURE-COMPLETENESS-FRONTIER.52?"
date: 2026-06-13
status: current
tags: [ial2, axi, manager, rlast, bursts, response-demux, metadata, ppif, task-tree]
evidence: docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md; docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1436-ial2-ppif-parser-cli.t; t/1437-axi-ial2-manager-capacity-status-generator.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.53|AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT|generated burst-last' docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.51` ships parser/report metadata and
static validation for the bounded AXI read `response-demux` scope
`response-scope burst-last` plus one-bit `last-signal`.

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

The report is structural only. `response_demux.generated_behavior` and
`response_demux.read.generated_behavior` are `false`; the residue includes
`generated_burst_last_read_demux`, `read_data_interleaving`, and `bursts`.
Generated `.isf`, `.fsm`, and HDL artifacts remain unchanged from the base
read auto-ID lifecycle capacity/status shell used for this report-only sample.

The parser rejects `last-signal` on `single-beat`, rejects `burst-last`
without exactly one width-1 `last-signal`, checks name collisions involving
that signal, and rejects the current single-beat `read-data` contract when it
is paired with burst-last response demux.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.52` audited readiness and selected direct
generated burst-last/`RLAST` completion behavior. `IAL2-FEATURE-COMPLETENESS-FRONTIER.53`
shipped that behavior while keeping read-data reassembly deferred. The next
active slice is `IAL2-FEATURE-COMPLETENESS-FRONTIER.54`: select the next AXI
manager feature-completeness owner.
