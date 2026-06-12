---
id: ial2-axi-manager-auto-id-residue-alignment-first-slice
title: Auto-ID lifecycle residue is aligned after generated write response demux
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.32 ship?"
  - "does auto_id_lifecycle.residue still include response_demux?"
  - "what is the auto-ID lifecycle residue after generated write BID demux?"
  - "did residue alignment change generated HDL?"
date: 2026-06-12
status: current
tags: [ial2, axi, manager, response-demux, auto-id, residue, task-tree]
evidence: docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; t/1437-axi-ial2-manager-capacity-status-generator.t; t/1436-ial2-ppif-parser-cli.t; ppif/axi_manager_capacity_status_response_demux.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; docs/book/src/14-feature-backlog.md; README.md; ROADMAP_V2.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.32|auto_id_lifecycle\\.residue|same_id_ordering|response_demux|generated write BID' docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm t/1437-axi-ial2-manager-capacity-status-generator.t t/1436-ial2-ppif-parser-cli.t docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/book/src/14-feature-backlog.md README.md ROADMAP_V2.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.32` shipped the report-contract cleanup
selected by `.31`.

When explicit `response_demux.generated_behavior` is true, FSMGen now removes
`response_demux` from `auto_id_lifecycle.residue`, because generated demux
completion pulses drive auto-ID release. The checked-in response-demux sample
now reports:

```text
auto_id_lifecycle.residue:
  - same_id_ordering
```

Samples without generated response-demux behavior keep their existing
`response_demux` residue under `auto_id_lifecycle`.

This slice is report-only. It does not change generated `.isf`, generated
`.fsm`, or SystemVerilog HDL behavior.

The follow-up selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` chose
`IAL2-FEATURE-COMPLETENESS-FRONTIER.34`, AXI same-ID ordering readiness,
because `same_id_ordering` is now the shared remaining ID/auto-ID/write-demux
residue.
