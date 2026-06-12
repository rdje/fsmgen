---
id: ial2-axi-manager-read-response-demux-behavior-first-slice
title: AXI read response demux behavior ships generated RID matching
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.41 ship?"
  - "does read response-demux generate RID demux behavior?"
  - "does AXI read response demux generate completion pulses?"
  - "what is response_demux.read generated behavior?"
  - "what comes after generated read response demux?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, read-response, response-demux, rid, behavior, auto-id, task-tree]
evidence: docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ppif/axi_manager_capacity_status_read_response_demux.ppif; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.41|response_demux\\.read|generated_behavior: true|axi0_r0_response_demux|axi0_read_response_demux_active_match|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.42' docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.41` shipped bounded generated
single-beat AXI read `RID` response-demux behavior for the explicit read
`response-demux` arm.

The generator now adds the read response ID signal as a generated IAL1 input,
exposes selected read transaction completion names as generated pulse outputs,
emits one `(pulse COMPLETION)` demux rule per read auto-ID transaction, and
emits read active-match plus unique-match assertions. Read capacity release
and read auto-ID release consume those generated completion pulses.

Schedule JSON reports `response_demux.generated_behavior: true` and
`response_demux.read.generated_behavior: true` with generated read rules,
completion signals, and assertions. The read response-demux residue is now
`[read_data_interleaving, bursts]`.

The next active leaf is `IAL2-FEATURE-COMPLETENESS-FRONTIER.42`, a selector
for the next SV-backed IAL2 feature-completeness slice. Read-data
interleaving/reassembly, bursts/`RLAST`, per-ID queues, queued/blocking
policy, full-manager behavior, direct backend lowering, and VHDL remain future
exact-owner work.
